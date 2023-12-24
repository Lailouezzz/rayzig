const std = @import("std");

const vector = @import("vector.zig");

pub const Ray = struct {
	const Self = @This();

	pub const Hit = struct {
		t: vector.FloatType = undefined,
		normal: vector.Vector3f = undefined,
		p: vector.Point3f = undefined,
		// what: *anyopaque = undefined,

		pub fn init(ray: Ray, t: vector.FloatType, outwardNormal: vector.Vector3f, p: vector.Point3f) @This() {
			const normal = if (ray.dir.dot(outwardNormal) < 0) outwardNormal else outwardNormal.mul(-1);

			return @This() {
				.t = t,
				.normal = normal,
				.p = p,
			};
		}
	};

	orig: vector.Point3f,
	dir: vector.Vector3f,

	pub fn init(orig: vector.Point3f, dir: vector.Vector3f) Self {
		return Self {
			.orig = orig,
			.dir = dir,
		};
	}

	pub fn at(self: Self, t: vector.FloatType) vector.Point3f {
		return self.orig.add(self.dir.mul(t));
	}
};
