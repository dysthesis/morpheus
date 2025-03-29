const std = @import("std");
const json = std.json;
const types = @import("types.zig");

/// Information on the server as a whole, required for a client to establish connection to it.
pub const ServerInfo = struct {
    /// The version info of the server
    version: ServerVersion,

    /// Statistics on currently connected players.
    players: ServerPlayers(u8), // Server player counts can't be negative, so use unsigned types.

    /// The description of the server.
    description: []u8,

    // TODO: figure out what exactly this field is for
    enforcesSecureChat: bool,

    pub fn toJSON(allocator: std.heap.Allocator, self: ServerInfo) ![]u8 {
        const result = try json.stringifyAlloc(allocator, self, .{});
        return result;
    }
};

/// Information on the supported game version and protocol version number.
pub const ServerVersion = struct {
    /// The version of Minecraft that this protocol supports.
    name: []u8,

    /// The protocol version used by the server. See: https://minecraft.wiki/w/Protocol_version.
    protocol: u16, // This should be big enough
};

/// Statistics on how many players the server can support, and who and how many are currently logged
/// on. This type is made generic over some integer type I in order to easily support increasing the
/// number of players supported.
// TODO: figure out a way to enforce that `I` must be an integer type.
pub fn ServerPlayers(comptime I: type) type {
    return struct {
        max: I,
        online: I,
    };
}
