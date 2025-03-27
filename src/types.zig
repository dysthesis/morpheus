// Originally from:
// https://github.com/regenerativep/zigmcp/blob/f3a5d84ed361120163e38399722ecf36c7f456b3/src/varint.zig

const std = @import("std");

/// This function takes in an arbitrary integer type `I` and returns a VarInt type that spans said
/// integer type.
///
/// Variable-length integers such that smaller values occupies less memory.
///
/// These are encoded in 8-bit chunks, where
///
/// - the 7 least significant bits are used to encode the value, and
/// - the most significant bit indicates whether there is another chunk after it for the next part
///   of the number
///
/// `VarInt`s are little endian, but with 7-bit groups rather than 8.
///
/// `VarInt`s are never longer than 5 bytes.
///
/// `VarInt`s are generic over arbitrary integer types (`i8`, `i16``, etc.)
pub fn VarInt(comptime I: type) type {
    // Get the type information of the integer type we are using. This is necessary to construct
    // our `VarInt` type to fit the integer type we are using.
    const typeinfo = @typeInfo(I).Int;

    // A bitmask to get the bit indicating if there is another chunk after this.
    const CONTINUE_BITS = 0x80;

    return struct {
        /// The unsigned version of I, used as a 'buffer' to contain the bits read while they are
        /// being processed. This is because the encoding or decoding of `VarInt`s, by definition,
        /// involves isolating 7 bits at a time. Using a signed type could result in sign extensions
        /// during bit shifting; that is, extra 1 bits could appear on the left if the number is
        /// negative.
        pub const Unit = @Type(.Int{ .signedness = .unsigned, .bits = typeinfo.bits });

        /// This represents the maximum number of 7-bit chunks are needed to represent an integer
        /// with the bit width of `I`.
        pub const MaxBytes = (typeinfo.bits + 6) / 7;

        /// A `Chunk` of the `VarInt`, as per the specifications. The 7 least significant bits hold
        /// data while the most significant bit determines whether there is another chunk after it.
        pub const Chunk = if (typeinfo.bits < 8) I else u8;

        // TODO: Reading can probably be improved. The value of each chunk can be obtained in
        // parallel to the reading of chunks. See: https://github.com/as-com/varint-simd
        pub fn read(reader: std.io.Reader(u8), out: *I) !void {
            var result: Unit = 0;

            for (0..MaxBytes) |pos| {
                const curr_chunk = try reader.readByte();

                // Check if there is another chunk after this, but it won't fit.
                const continues = ((curr_chunk & CONTINUE_BITS) != 0);
                if (continues and pos == MaxBytes - 1) {
                    return error.VarIntTooBig;
                }

                // Get the position of the data section of the current chunk (the 7 last bits).
                const data_pos = 7 * @as(std.math.Log2Int(Unit), @intCast(pos));

                // Get the value of the current chunk, and combine it with the `result`
                result |= @as(Unit, @as(u7, @truncate(curr_chunk))) << data_pos;

                if (!continues) break;
            }

            // TODO: Try to refactor this into a constructor, with I as an internal value instead.
            out.* = @bitCast(result);
        }
    };
}
