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
    var timer = try std.time.Timer.start();
    if (fork_pid == 0) {
        const envp = std.c.environ;
        const argv = std.os.argv[1..];
        const result = std.posix.execvpeZ(argv[0], @ptrCast(argv), @ptrCast(envp));
        std.debug.print("ERROR: {}\n", .{result});
    } else {
        const wait = std.posix.waitpid(fork_pid, 0);
        if (wait.status != 0) {
            std.debug.print("child: {}\n", .{wait});
        }
        const rusage = std.posix.getrusage(std.posix.rusage.CHILDREN);
        const timerSec = @divTrunc(std.time.Timer.read(&timer), std.time.ns_per_s);
        const timerMs = @divTrunc(std.time.Timer.read(&timer), std.time.ns_per_ms) - (timerSec * std.time.ms_per_s);

        std.debug.print("======================\nReal\t{}.{}s\nUser\t{}.{}s\nSys\t{}.{}s\n", .{ timerSec, timerMs, rusage.utime.sec, @divTrunc(rusage.utime.usec, std.time.us_per_ms), rusage.stime.sec, @divTrunc(rusage.stime.usec, std.time.us_per_ms) });
    }
}
