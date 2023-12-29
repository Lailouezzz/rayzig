const std = @import("std");

const Lehmer = @import("Lehmer.zig");

const RandDefault = Lehmer;

pub threadlocal var rng: RandDefault = undefined;

pub fn init() void {
	rng = RandDefault.init(@intCast(std.time.nanoTimestamp()));
}
