const std = @import("std");

const time = std.time;

const xev = @import("xev");

const ThreadPool = xev.ThreadPool;

pub fn main() !void {
    var tp = ThreadPool.init(.{});
    defer tp.deinit();

    var task1 = ThreadPool.Task{
        .callback = callback,
    };
    var task2 = ThreadPool.Task{
        .callback = callback,
    };

    const batch1 = ThreadPool.Batch.from(&task1);
    const batch2 = ThreadPool.Batch.from(&task2);

    tp.schedule(batch1);
    tp.schedule(batch2);
}

fn callback(_: *ThreadPool.Task) void {
    time.sleep(time.ns_per_s * 1);
    std.debug.print("hello\n", .{});
}
