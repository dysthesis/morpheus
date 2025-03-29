const types = @import("main.zig");
const std = @import("std");
/// An interface for protocol-specific data encoding.
///
/// Invariants:
///
/// - `encode()` and `decode()` are inverse functions; that is, `decode(encode(x)) == x`.
pub fn Codec(comptime I: type) type {
    return union(enum) {
        varInt: types.VarInt(I),
        pub fn decode(self: Codec(I), reader: std.io.reader(u8)) !I {
            return switch (self) {
                inline else => |s| s.decode(reader),
            };
        }

        pub fn encode(self: Codec(I), writer: anytype) !void {
            switch (self) {
                inline else => |s| s.encode(writer),
            }
        }
    };
}
