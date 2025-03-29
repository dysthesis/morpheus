const std = @import("std");
const net = std.net;

const Server = @import("Server.zig").Server;

/// Represents a client: that is, an instance of a player connected to this server.
pub const Client = struct {
    state: enum(u8) {
        handshake,
        status,
        login,
        configuration,
        play,
    } = .{ .raw = .handshake },

    /// The IP address of the client
    address: net.Address,

    /// The instance of the server this client is connected to
    server: Server,

    /// The memory allocator to use
    allocator: std.mem.Allocator,

    /// Identifier of this client
    id: usize,

    /// Initialise an instance of the `Client`
    pub fn init(self: *Client, id: usize, address: net.Address, server: Server, allocator: std.mem.Allocator) void {
        self.* = .{
            .id = id,
            .address = address,
            .server = server,
            .allocator = allocator,
        };
    }
};
