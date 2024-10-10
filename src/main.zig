const std = @import("std");

//TODO:
//  add minute counter
//  do a test
//  use the stdio

pub fn main() !void {
    if (std.os.argv.len < 2) {
        std.debug.print("no argument provided for {s}.\nusage:\n...\n", .{std.os.argv[0]});
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
        const wait = std.posix.waitpid(fork_pid, 0);
        if (wait.status != 0) {
            std.debug.print("child: {}\n", .{wait});
        }
        const timerSec = @divFloor(std.time.Timer.read(&timer), std.time.ns_per_s);
        const timerMs = @divFloor(std.time.Timer.read(&timer), std.time.ns_per_ms) - (timerSec * std.time.ms_per_s);
        const rusage = std.posix.getrusage(std.posix.rusage.CHILDREN);

        std.debug.print("======================\nReal\t{}.{:0>3}s\nUser\t{}.{:0>3}s\nSys\t{}.{:0>3}s\n", .{ timerSec, timerMs, rusage.utime.sec, @divFloor(@as(usize, @bitCast(rusage.utime.usec)), std.time.us_per_ms), rusage.stime.sec, @divFloor(@as(usize, @bitCast(rusage.stime.usec)), std.time.us_per_ms) });
    }
}
