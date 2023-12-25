const std = @import("std");

pub threadlocal var rng: std.rand.DefaultPrng = undefined;

pub fn init() void {
	rng = std.rand.DefaultPrng.init(@as(u64,@intCast(std.time.microTimestamp())));
}
