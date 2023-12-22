const std = @import("std");

const vector = @import("vector.zig");

pub const Ray = struct {
	const Self = @This();

	pub const Hit = struct {
		t: vector.Coord = undefined,
		normal: vector.Vector3f = undefined,
		p: vector.Point3f = undefined,
	};

	orig: vector.Point3f,
	dir: vector.Vector3f,

	pub fn init(orig: vector.Point3f, dir: vector.Vector3f) Self {
		return Self {
			.orig = orig,
			.dir = dir,
		};
	}

	pub fn at(self: Self, t: vector.Coord) vector.Point3f {
		return self.orig.add(self.dir.mul(t));
	}
};
