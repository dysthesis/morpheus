// Originally from
// https://github.com/regenerativep/zigmcp/blob/f3a5d84ed361120163e38399722ecf36c7f456b3/src/varint.zig

const std = @import("std");
const testing = std.testing;

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

    const DATA_BITS_COUNT = 7;

    return struct {
        value: I,
        pub const Self = VarInt(I);
        /// The unsigned version of I, used as a 'buffer' to contain the bits read while they are
        /// being processed. This is because the encoding or decoding of `VarInt`s, by definition,
        /// involves isolating 7 bits at a time. Using a signed type could result in sign extensions
        /// during bit shifting; that is, extra 1 bits could appear on the left if the number is
        /// negative.
        pub const UnsignedSelf = @Type(.Int{ .signedness = .unsigned, .bits = typeinfo.bits });

        /// This represents the maximum number of 7-bit chunks are needed to represent an integer
        /// with the bit width of `I`.
        pub const MaxBytes = (typeinfo.bits + 6) / 7;

        /// A `Chunk` of the `VarInt`, as per the specifications. The 7 least significant bits hold
        /// data while the most significant bit determines whether there is another chunk after it.
        pub const Chunk = if (typeinfo.bits < 8) I else u8;

        /// Initialise a new instance of `VarInt`
        pub fn init(reader: std.io.Reader(u8)) !I {
            const value: I = decode(reader);
            return Self{ .value = value };
        }

        // TODO: Reading can probably be improved. The value of each chunk can be obtained in
        // parallel to the reading of chunks. See: https://github.com/as-com/varint-simd.
        // Try benchmarking this, and use SIMD if there is a bottleneck here.

        /// Given a chunk, align its data segment to its appropriate position.
        inline fn alignChunkData(chunk: u8, chunk_pos: u8) UnsignedSelf {
            // Get the position of the data section of the current chunk in the resulting Unit
            const data_pos = 7 * @as(std.math.Log2Int(UnsignedSelf), @intCast(chunk_pos));

            // Get the value of the current chunk, and combine it with the `result`
            const data = @as(UnsignedSelf, @as(u7, @truncate(chunk))) << data_pos;

            return data;
        }

        /// Decodes the given chunk, returning the `continue` indicator and the correctly-aligned
        /// data.
        inline fn decodeChunk(chunk: u8, pos: u8) struct { bool, UnsignedSelf } {
            const curr_chunk = chunk;
            // Check if there is another chunk after this, but it won't fit.
            const continues = ((curr_chunk & CONTINUE_BITS) != 0);
            if (continues and pos == MaxBytes - 1) {
                return error.VarIntTooBig;
            }

            const data = alignChunkData(curr_chunk, pos);
            return .{ continues, data };
        }

        /// Read in chunks and return the resulting value.
        pub fn decode(reader: std.io.Reader(u8)) !I {
            var result: UnsignedSelf = 0;

            for (0..MaxBytes) |pos| {
                const curr_chunk = try reader.readByte();
                const continues, const data = decodeChunk(curr_chunk, pos);

                result |= data;
                if (!continues) break;
            }

            return @bitCast(result);
        }

        pub fn write(self: Self, writer: anytype) !void {
            // Ensure that `writer` has the necessary methods
            comptime {
                _ = writer.writeByte;
            }

            var value: UnsignedSelf = @bitCast(self.value);
            while (true) {
                const data: u8 = @as(u7, @truncate(value));

                // PERF: This is a branchless statement that is equivalent to the following
                // conditional:
                //
                // if (typeinfo.bits < 8)
                //     value = 0
                // else
                //     value >>= 7;
                //
                // This should be more efficient than its implementation with branching.
                // See: https://en.algorithmica.org/hpc/pipelining/branching
                value = (value >> 7) * @intFromBool(typeinfo.bits >= 8);

                // PERF: Likewise here, although we can't completely eliminate branching, we can
                // avoid its costs on as many code paths as we can. This code is equivalent to:
                //
                // if (value == 0) {
                //     try writer.writeByte(data);
                //     break;
                // } else {
                //     try writer.writeByte(data | 0b1000_0000);
                // }
                try writer.writeByte(data | @as(u8, @intFromBool(value != 0)) << DATA_BITS_COUNT);

                if (value == 0) break;
            }
        }
    };
}

// TODO: see if we can fuzz-test this instead
pub const VarIntTestCases = .{
    .{ .Type = i32, .value = 0, .chunks = .{0x00} },
    .{ .Type = i32, .value = 1, .chunks = .{0x01} },
    .{ .Type = i32, .value = 2, .chunks = .{0x02} },
    .{ .Type = i32, .value = 127, .chunks = .{0x7f} },
    .{ .Type = i32, .value = 128, .chunks = .{ 0x80, 0x01 } },
    .{ .Type = i32, .value = 255, .chunks = .{ 0xff, 0x01 } },
    .{ .Type = i32, .value = 25565, .chunks = .{ 0xdd, 0xc7, 0x01 } },
    .{ .Type = i32, .value = 2097151, .chunks = .{ 0xff, 0xff, 0x7f } },
    .{ .Type = i64, .value = 2147483647, .chunks = .{ 0xff, 0xff, 0xff, 0xff, 0x07 } },
    .{ .Type = i64, .value = -1, .chunks = .{ 0xff, 0xff, 0xff, 0xff, 0x0f } },
    .{ .Type = i64, .value = -2147483648, .chunks = .{ 0x80, 0x80, 0x80, 0x80, 0x08 } },
};

test "VarInt read" {
    inline for (VarIntTestCases) |case| {
        const buf: [case.value.len]u8 = case.value;
        var reader = std.io.fixedBufferStream(&buf);
        const VarIntType = VarInt(case.Type);
        const result: VarIntType = try VarIntType.fromBytes(reader.reader());
        try testing.expectEqual(@as(case.Type, case.value), result.value);
    }
}
