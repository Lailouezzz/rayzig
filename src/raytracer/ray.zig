const std = @import("std");

const vector = @import("math").vector;

const Material = @import("material.zig").Material;

pub const Ray = struct {
	const Self = @This();

	pub const Hit = struct {
		t: vector.FloatType = undefined,
		normal: vector.Vector3f = undefined,
		frontFace: bool = undefined,
		p: vector.Point3f = undefined,
		fromDir: vector.Vector3f = undefined,
		what: Material = undefined,

		pub fn init(ray: Ray, t: vector.FloatType, outwardNormal: vector.Vector3f, what: Material) @This() {
			return hit: {
				const frontFace = (ray.dir.dot(outwardNormal) < 0);
				const normal = if (frontFace) outwardNormal else outwardNormal.mul(-1);
				break :hit @This() {
					.t = t,
					.normal = normal,
					.frontFace = frontFace,
					.p = ray.at(t),
					.fromDir = ray.dir,
					.what = what,
				};
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
