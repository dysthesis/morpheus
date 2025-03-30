use std::{
    io::{Read, Write},
    num::NonZeroUsize,
    slice,
};

use crate::types::Codec::Codec;

/// We use i64 as an internal type because the largest length for a VarInt is 5 bytes; an i64 is
/// the smallest type that can fit such a worst case scenario.
type Inner = i64;

/// The unsigned version of `Inner`, used as a 'buffer' to contain the bits read while they are
/// being processed. This is because the encoding or decoding of `VarInt`s, by definition,
/// involves isolating 7 bits at a time. Using a signed type could result in sign extensions
/// during bit shifting; that is, extra 1 bits could appear on the left if the number is
/// negative.
type UnsignedInner = u64;

/// The number of bits in the inner type (64, since it's an i64)
const INNER_TYPE_WIDTH: usize = 64;

#[derive(Debug)]
pub struct VarInt(pub Inner);

impl VarInt {
    /// A bitmask to get the bit indicating if there is another chunk after this.
    pub const CONTINUE_BITS: u8 = 0x80;

    /// A bitmask to get the data bits of the chunk.
    pub const DATA_BITS: u8 = 0x7F;

    /// Align the data segment of the given `chunk` to its appropriate place in the result
    fn align_chunk(chunk: u8, chunk_pos: usize) -> UnsignedInner {
        // Get the position of the data section of the current chunk in the result
        let data_pos: usize = 7 * chunk_pos;

        // Get the value of the current chunk, move it to its proper position
        let data: UnsignedInner = (chunk << data_pos).into();
        return data;
    }

    /// Decodes the given chunk, returning the `continue` indicator  and the correctly-aligned
    /// data.
    fn decode_chunk(chunk: u8, pos: usize) -> Result<(bool, UnsignedInner), ()> {
        let continues: bool = (chunk & Self::CONTINUE_BITS) != 0;
        if continues && (pos == Self::MAX_SIZE.get() - 1) {
            return Err(());
        }
        let data: UnsignedInner = VarInt::align_chunk(chunk, pos);

        Ok((continues, data))
    }
}

impl Codec<VarInt> for VarInt {
    const MAX_SIZE: NonZeroUsize = NonZeroUsize::new(5).expect("this is nonzero");
    fn encode(&self, writer: &mut impl Write) -> Result<(), ()> {
        let mut value: UnsignedInner = self.0.try_into().map_err(|_| ())?;
        for _ in 0..VarInt::MAX_SIZE.get() {
            let data: u8 = value as u8 & VarInt::DATA_BITS;
            // PERF: This is a branchless statement that is equivalent to the following
            // conditional:
            //
            // if (INNER_TYPE_WIDTHs < 8)
            //     value = 0
            // else
            //     value >>= 7;
            //
            // This should be more efficient than its implementation with branching.
            // See: https://en.algorithmica.org/hpc/pipelining/branching
            value = (value >> 7) * ((INNER_TYPE_WIDTH >= 8) as UnsignedInner);

            // PERF: Likewise here, although we can't completely eliminate branching, we can
            // avoid its costs on as many code paths as we can. This code is equivalent to:
            //
            // let to_write: u8 = if value == 0 { data } else { data | VarInt::DATA_BITS }
            let to_write: u8 = data & (VarInt::DATA_BITS | ((value == 0) as u8));
            let _ = writer.write_all(&[to_write]).map_err(|_| ())?;

            if value == 0 {
                break;
            }
        }
        Ok(())
    }

    /// Read in a stream of bytes from a reader and parse it into an integer.
    ///
    /// * `reader`: The reader to take in bytes from.
    fn decode(reader: &mut impl Read) -> Result<VarInt, ()> {
        let mut result: UnsignedInner = 0;
        for pos in 0..VarInt::MAX_SIZE.get() {
            // Read in the byte
            let mut chunk: u8 = 0;
            reader
                .read_exact(slice::from_mut(&mut chunk))
                .map_err(|_| ())?;

            let (continues, data) = match VarInt::decode_chunk(chunk, pos) {
                Ok(res) => res,
                Err(_) => {
                    return Err(());
                }
            };
            result |= data;
            if !continues {
                break;
            }
        }
        // Cast it back into a signed type
        let result: Inner = result.try_into().map_err(|_| ())?;
        Ok(VarInt(result))
    }
}

#[cfg(test)]
mod test {
    use super::*;
    use proptest::prelude::*;
    use std::io::Cursor;
    const VARINT_MAX: Inner = 2_i64.pow(5 * 8);

    proptest! {
        #![proptest_config(ProptestConfig::with_cases(1000000))]
        #[test]
        fn encode_decode_are_invertible(val in 0..VARINT_MAX) {
            // Wrap the given value in VarInt
            let var_int = VarInt(val);

            // Mock an actual stream of bytes
            let mut buf = [0u8; 5];

            // Turn it into a `Reader` and a `Writer`.
            let mut buf = Cursor::new(&mut buf[..]);

            var_int.encode(&mut buf).unwrap();
            buf.set_position(0);

            let var_int_copy = VarInt::decode(&mut dbg!(buf)).unwrap();

            prop_assert_eq!(var_int.0, var_int_copy.0);
        }
    }
}
