pub fn main() !void {
    const port: u16 = 8080;
    try runServer(port);
}

// Runs a server at the given port
fn runServer(port: u16) !void {
    // Create a TCP server
    const address = net.Address.initIp4(.{ 0, 0, 0, 0 }, port);
    var server = try address.listen(.{});

    std.debug.print("Server listening on {}\n", .{address});

    while (true) {
        // accept a connection
        const client = try server.accept();
        defer client.stream.close();
        std.debug.print("Accepted connection from {}\n", .{client.address});

        // handle connection
        try handleConnection(client);
    }
}

// Handles each connection accepted by the servedr
fn handleConnection(client: net.Server.Connection) !void {
    defer client.stream.close();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    const stream = client.stream;
    const reader = stream.reader();
    const writer = stream.writer();
    const max_size: u8 = 100;

    while (true) {
        const message = try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', max_size) orelse "";

        // client closed the connection
        if (message.len == 0) break;

        std.debug.print("Received: {s}\n", .{message});

        // TODO: actual action here
        // Echo the data back to the client
        _ = try writer.writeAll(message);
    }

    std.debug.print("Connection closed\n", .{});
}

// Test helper function
fn connectToServer(port: u16) !net.Stream {
    const address = try net.Address.resolveIp("127.0.0.1", port);
    return try net.tcpConnectToAddress(address);
}

const std = @import("std");
const net = std.net;
const testing = std.testing;
const Thread = std.Thread;

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("morpheus_lib");

test "server echoes data" {
    const test_port: u16 = 8081;
    var server_thread = try Thread.spawn(.{}, runServer, .{test_port});

    std.time.sleep(100 * std.time.ns_per_ms);

    {
        const client = try connectToServer(test_port);
        defer client.close();

        // Send the message
        const message = "69420";
        _ = try client.write(message);

        // Read the response
        var buf: [128]u8 = undefined;
        const bytes_read = try client.read(buf);

        // The response should be the same as the messge
        try testing.expectEqualStrings(message, buf[0..bytes_read]);
    } // client closed

    // wait for the server to finish
    server_thread.join();
}
