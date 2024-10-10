const std = @import("std");
//TODO:
//  do a test
//  add verbose option

pub fn main() !void {
    if (std.os.argv.len <= 1) {
        try std.io.getStdOut().writer().print("no argument provided.\nusage:\n{s} command...\n", .{std.os.argv[0]});
        return;
    }
    const fork_pid = try std.posix.fork();
    const envp = std.c.environ;
    const argv = std.os.argv[1..];
    var timer = try std.time.Timer.start();
    if (fork_pid == 0) {
        const result = std.posix.execvpeZ(argv[0], @ptrCast(argv), @ptrCast(envp));
        std.debug.print("ERROR: {}\n", .{result});
    } else {
        _ = std.posix.waitpid(fork_pid, 0);
        const timerSec = std.time.Timer.read(&timer) / std.time.ns_per_s;
        const timerMs = (std.time.Timer.read(&timer) / std.time.ns_per_ms) % std.time.ms_per_s;
        const rusage = std.posix.getrusage(std.posix.rusage.CHILDREN);

        try std.io.getStdOut().writer().print("\nReal\t{}m{}.{:0>3}s\nUser\t{}m{}.{:0>3}s\nSys\t{}m{}.{:0>3}s\n", .{ @divFloor(timerSec, 60), timerSec % 60, timerMs, @divFloor(rusage.utime.sec, 60), @mod(rusage.utime.sec, 60), @divFloor(@as(usize, @bitCast(rusage.utime.usec)), std.time.us_per_ms), @divFloor(rusage.utime.sec, 60), @mod(rusage.stime.sec, 60), @divFloor(@as(usize, @bitCast(rusage.stime.usec)), std.time.us_per_ms) });
    }
}
