const std = @import("std");

const Lehmer = @This();

state: u128 = undefined,

pub fn init(init_s: u128) Lehmer {
	var l =  Lehmer {
		.state = init_s,
	};
	_ = l.next();
	return l;
}

pub fn random(self: *Lehmer) std.rand.Random {
	return std.rand.Random.init(self, fill);
}

pub fn next(self: *Lehmer) u64 {
	self.state *= 0xda942042e4dd58b5;
	return (@truncate(self.state >> 64));
}

pub fn fill(self: *Lehmer, buf: []u8) void {
	const alignedBlock = buf.len >> 3;

	for (0..alignedBlock) |k| {
		var r = self.next();
		inline for (0..8) |j| {
			buf[k * 8 + j] = @as(u8, @truncate(r));
			r >>= 8;
		}
	}
	const remaining = buf.len & 7;
	if (remaining != 0) {
		var r = self.next();
		for (alignedBlock * 8.. alignedBlock * 8 + remaining) |k| {
			buf[k] = @as(u8, @truncate(r));
			r >>= 8;
		}
	}
}