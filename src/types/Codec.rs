use std::{
    io::{Read, Write},
    num::NonZeroUsize,
};

/// An interface for the data types defined by the Minecraft server protocol.
pub(crate) trait Codec<T> {
    const MAX_SIZE: NonZeroUsize;
    fn encode(&self, writer: &mut impl Write) -> Result<(), ()>;
    fn decode(reader: &mut impl Read) -> Result<T, ()>;
}
