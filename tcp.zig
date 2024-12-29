const std = @import("std");

const xev = @import("xev");

const timer = xev.Timer;

// minimal example for repeated event
pub fn main() !void {
    var loop = try xev.Loop.init(.{});
    defer loop.deinit();

    const addr = try std.net.Address.parseIp("127.0.0.1", 3131);
    var tcp = try xev.TCP.init(addr);
    var c: xev.Completion = undefined;
    var s: Some = undefined;
    tcp.connect(&loop, &c, addr, Some, &s, callback);

    // Tick
    try loop.run(.until_done);
}

fn callback(s: ?*Some, l: *xev.Loop, c: *xev.Completion, tcp: xev.TCP, err: xev.TCP.ConnectError!void) xev.CallbackAction {
    std.debug.print("connected: {any}\n", .{err});
    err catch return .disarm;

    const PING = "PING\n";
    tcp.write(l, c, .{ .slice = PING[0..PING.len] }, Some, s, writeCallback);

    return .disarm;
}

fn writeCallback(s: ?*Some, l: *xev.Loop, c: *xev.Completion, tcp: xev.TCP, buf: xev.WriteBuffer, err: xev.WriteError!usize) xev.CallbackAction {
    _ = buf;

    var b: [1024]u8 = undefined;

    std.debug.print("write: {any}\n", .{err});
    tcp.read(l, c, .{ .slice = &b }, Some, s, readCallback);

    return .disarm;
}

fn readCallback(s: ?*Some, l: *xev.Loop, c: *xev.Completion, tcp: xev.TCP, b: xev.ReadBuffer, r: xev.ReadError!usize) xev.CallbackAction {
    _ = s;
    _ = l;
    _ = c;
    _ = tcp;
    _ = b;

    std.debug.print("read: {any}\n", .{r});

    return .disarm;
}

const Some = struct {};
