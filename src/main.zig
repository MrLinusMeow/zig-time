const std = @import("std");

pub fn main() !void {
    const usage = "\x1B[1mUSAGE: ./time command...\x1B[0m\nOPTIONS:\n\t-p\t Write the timing output to standard error.\n\n";
    const timing = "\nReal\t{}m{}.{:0>3}s\nUser\t{}m{}.{:0>3}s\nSys\t{}m{}.{:0>3}s\n";
    if (std.os.argv.len <= 1) {
        std.debug.print("\x1B[91mERROR: No argument provided.\x1B[0m\n", .{});
        try std.io.getStdOut().writer().print("{s}", .{usage});
        return;
    }
    const stderr = std.mem.eql(u8, std.os.argv[1][0..2], "-p");
    const argv = if (stderr) std.os.argv[2..] else std.os.argv[1..];
    if (argv.len == 0) {
        std.debug.print("\x1B[91mERROR: No command provided.\x1B[0m\n", .{});
        try std.io.getStdOut().writer().print("{s}", .{usage});
        return;
    }
    const envp = std.c.environ; // C LIB
    const fork_pid = try std.posix.fork();
    var timer = try std.time.Timer.start();
    if (fork_pid == 0) {
        const result = std.posix.execvpeZ(argv[0], @ptrCast(argv), @ptrCast(envp));
        std.debug.print("\x1B[91mERROR: {} {s}\x1B[0m\n", .{ result, argv[0] });
        try std.io.getStdOut().writer().print("{s}", .{usage});
    } else {
        const wait = std.posix.waitpid(fork_pid, 0);
        if (wait.status != fork_pid) {
            const timerSec = std.time.Timer.read(&timer) / 1_000_000_000;
            const timerMs = (std.time.Timer.read(&timer) / 1_00) % 1_00;
            const rusage = std.posix.getrusage(std.posix.rusage.CHILDREN);
            if (stderr) {
                std.debug.print(timing, .{ @divFloor(timerSec, 60), timerSec % 60, timerMs, @divFloor(rusage.utime.sec, 60), @mod(rusage.utime.sec, 60), @divFloor(@as(usize, @bitCast(rusage.utime.usec)), std.time.us_per_ms), @divFloor(rusage.utime.sec, 60), @mod(rusage.stime.sec, 60), @divFloor(@as(usize, @bitCast(rusage.stime.usec)), std.time.us_per_ms) });
            } else {
                try std.io.getStdOut().writer().print(timing, .{ @divFloor(timerSec, 60), timerSec % 60, timerMs, @divFloor(rusage.utime.sec, 60), @mod(rusage.utime.sec, 60), @divFloor(@as(usize, @bitCast(rusage.utime.usec)), std.time.us_per_ms), @divFloor(rusage.utime.sec, 60), @mod(rusage.stime.sec, 60), @divFloor(@as(usize, @bitCast(rusage.stime.usec)), std.time.us_per_ms) });
            }
        }
    }
}
