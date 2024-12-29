const std = @import("std");

const xev = @import("xev");

const timer = xev.Timer;

// minimal example for repeated event
pub fn main() !void {
    var loop = try xev.Loop.init(.{});
    defer loop.deinit();

    // fire off event then start timer
    // in case you want do waiting before event do:
    // loop.timer(&c, wait, null, callback);
    var c: xev.Completion = undefined;
    _ = callback(null, &loop, &c, .{ .noop = undefined });

    // Tick
    try loop.run(.until_done);
}

fn callback(_: ?*anyopaque, l: *xev.Loop, c: *xev.Completion, _: xev.Result) xev.CallbackAction {
    l.timer(c, 1_000, null, callback);
    std.debug.print("hhh\n", .{});

    return .disarm;
}
