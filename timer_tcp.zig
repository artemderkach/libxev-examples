const std = @import("std");

const Allocator = std.mem.Allocator;

const xev = @import("xev");

const timer = xev.Timer;

// minimal example for repeated event
pub fn main() !void {
    var loop = try xev.Loop.init(.{});
    defer loop.deinit();

    const GPA = std.heap.GeneralPurposeAllocator(.{});
    var gpa: GPA = .{};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var client = Client.init(alloc, &loop);
    var cb_client: ?*Client = undefined;
    cb_client = &client;

    var c: xev.Completion = undefined;
    _ = callback(cb_client, &loop, &c, .{ .noop = undefined });

    // try client.start();
    defer client.deinit();

    // Tick
    try loop.run(.until_done);
}

fn callback(ud: ?*anyopaque, l: *xev.Loop, c: *xev.Completion, _: xev.Result) xev.CallbackAction {
    // _ = c;
    // _ = l;

    const client: *Client = @ptrCast(@alignCast(ud.?));
    std.debug.print("-----: {any}\n", .{1});

    client.start() catch |e| {
        std.debug.print("read: {any}\n", .{e});
    };

    l.timer(c, 1_000, client, callback);

    return .disarm;
}

const CompletionPool = std.heap.MemoryPool(xev.Completion);

const Client = struct {
    loop: *xev.Loop,
    connection_pool: CompletionPool,
    read_buf: [1024]u8,

    pub const PING = "PING\n";

    fn init(alloc: Allocator, loop: *xev.Loop) Client {
        return .{
            .loop = loop,
            .connection_pool = CompletionPool.init(alloc),
            .read_buf = undefined,
        };
    }

    fn deinit(self: *Client) void {
        self.connection_pool.deinit();
    }

    fn start(self: *Client) !void {
        std.debug.print("-----: {any}\n", .{2});
        const addr = try std.net.Address.parseIp4("127.0.0.1", 3131);
        const socket = try xev.TCP.init(addr);

        std.debug.print("-----: {any}\n", .{11});
        const c = try self.connection_pool.create();
        socket.connect(self.loop, c, addr, Client, self, callbackConnect);
    }

    fn callbackConnect(self: ?*Client, l: *xev.Loop, c: *xev.Completion, tcp: xev.TCP, err: xev.TCP.ConnectError!void) xev.CallbackAction {
        std.debug.print("-----: {any}\n", .{3});
        std.debug.print("connected: {any}\n", .{err});
        err catch return .disarm;

        // const s = self.?;
        // Send message
        tcp.write(l, c, .{ .slice = PING[0..PING.len] }, Client, self, writeCallback);

        // const c_read = s.connection_pool.create() catch unreachable;

        return .disarm;
    }

    fn writeCallback(self: ?*Client, l: *xev.Loop, c: *xev.Completion, tcp: xev.TCP, _: xev.WriteBuffer, e: xev.WriteError!usize) xev.CallbackAction {
        std.debug.print("write: {any}\n", .{e});
        var s = self.?;

        tcp.read(l, c, .{ .slice = &s.read_buf }, Client, self, readCallback);

        return .disarm;
    }

    fn readCallback(self: ?*Client, l: *xev.Loop, c: *xev.Completion, tcp: xev.TCP, b: xev.ReadBuffer, r: xev.ReadError!usize) xev.CallbackAction {
        std.debug.print("read: {any}\n", .{r});
        const n = r catch unreachable;
        const data = b.slice[0..n];
        std.debug.print("read data: {s}\n", .{data});

        tcp.close(l, c, Client, self, closeCallback);
        // std.debug.print("read: {s}\n", .{data});

        return .disarm;
    }

    fn closeCallback(self: ?*Client, l: *xev.Loop, c: *xev.Completion, tcp: xev.TCP, r: xev.CloseError!void) xev.CallbackAction {
        _ = l;
        _ = tcp;
        std.debug.print("close: {any}\n", .{r});
        self.?.connection_pool.destroy(c);

        return .disarm;
    }
};
