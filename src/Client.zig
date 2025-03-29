const std = @import("std");
const net = std.net;
pub const Client = struct {
    state: enum(u8) {
        handshake,
        status,
        login,
        configuration,
        play,
    } = .{ .raw = .handshake },
    address: net.Address,
};
