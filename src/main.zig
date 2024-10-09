const std = @import("std");

//TODO:
//  add minute counter
//  do a test
//  use the stdio

pub fn main() !void {
    // start timer in nano seconds
    var timer = try std.time.Timer.start();

    // define resource usage of SELF, CHILDREN or THREAD.
    //const self = std.posix.rusage.SELF;
    const child = std.posix.rusage.CHILDREN;
    //const thread = std.posix.rusage.THREAD;

    // check if any arguments beside itself were passed
    if (std.os.argv.len < 2) {
        std.debug.print("no argument provided for {s}.\n", .{std.os.argv[0]});
        // get resource usage of specified flag
        const rusage = std.posix.getrusage(child);
        // get current state of the timer and convert it to seconds
        const timerSec = @divTrunc(std.time.Timer.read(&timer), std.time.ns_per_s);
        // get current state of the timer and convert it to mili-seconds
        const timerMs = @divTrunc(std.time.Timer.read(&timer), std.time.ns_per_ms) - (timerSec * std.time.ms_per_s);

        std.debug.print("======================\nReal\t{}.{}s\nUser\t{}.{}s\nSys\t{}.{}s\n", .{ timerSec, timerMs, rusage.utime.sec, @divTrunc(rusage.utime.usec, std.time.us_per_ms), rusage.stime.sec, @divTrunc(rusage.stime.usec, std.time.us_per_ms) });
        return;
    }
    // define enviroment
    const envp = std.c.environ;
    // create fork for new process
    const fork_pid = try std.posix.fork();
    if (fork_pid == 0) {
        // execute 1st passed argument
        const result = std.posix.execvpeZ(std.os.argv[1], @ptrCast(std.os.argv[1..]), @ptrCast(envp));
        std.debug.print("ERROR: {}\n", .{result});
    } else {
        // wait for the child process
        const wait = std.posix.waitpid(fork_pid, 0);
        if (wait.status != 0) {
            std.debug.print("child: {}\n", .{wait});
        }
        // get resource usage of specified flag
        const rusage = std.posix.getrusage(child);
        // get current state of timer and convert it to seconds
        const timerSec = @divTrunc(std.time.Timer.read(&timer), std.time.ns_per_s);
        // get current state of timer and convert it to mili-seconds
        const timerMs = @divTrunc(std.time.Timer.read(&timer), std.time.ns_per_ms) - (timerSec * std.time.ms_per_s);

        std.debug.print("======================\nReal\t{}.{}s\nUser\t{}.{}s\nSys\t{}.{}s\n", .{ timerSec, timerMs, rusage.utime.sec, @divTrunc(rusage.utime.usec, std.time.us_per_ms), rusage.stime.sec, @divTrunc(rusage.stime.usec, std.time.us_per_ms) });
    }
}
