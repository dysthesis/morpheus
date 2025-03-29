const std = @import("std");
const ping = @import("ping.zig");
const Client = @import("Client.zig").Client;
pub const Server = struct {
    info: ping.ServerInfo,
    pub fn handleStatusRequest(self: Server, client: Client) !void {
        const response =
            \\{
            \\    "version": {
            \\        "name": "
        ++ self.info.version.name ++
            \\",
            \\        "protocol":
        ++ std.fmt.comptimePrint(
            "{}",
            .{self.info.version.protocol},
        ) ++
            \\    },
            \\    "players": {
            \\        "max": 32,
            \\        "online": 0
            \\    },
            \\    "description": {
            \\        "text": "
        ++ self.info.description ++
            \\"
            \\    }
            \\}
        ;
    }
};
