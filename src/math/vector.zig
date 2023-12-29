const std = @import("std");

const rnd = @import("random.zig");

pub const FloatType = f32;
pub const Vector3f = Vector3(FloatType);
pub const Point3f = Vector3f;
pub const Color3f = Vector3f;

pub fn Vector3(comptime T: type) type {

	// Little check
	comptime {
		if (@typeInfo(T) != .Float)
			@compileError("Vector3 need a floating point type.");
	}

	return struct {
		const Self = @This();

		vec: @Vector(4, T),

		pub fn init(x: T, y: T, z: T) callconv(.Inline) Self {
			return Self {
				.vec = .{
					x,
					y,
					z,
					0,
				},
			};
		}

		pub fn add(v1: Self, v2: Self) callconv(.Inline) Self {
			return Self {
				.vec = v1.vec + v2.vec,
			};
		}

		pub fn sub(v1: Self, v2: Self) callconv(.Inline) Self {
			return Self {
				.vec = v1.vec - v2.vec,
			};
		}

		pub fn mul(self: Self, factor: T) callconv(.Inline) Self {
			return Self {
				.vec = self.vec * @as(@Vector(4, T), @splat(factor)),
			};
		}

		pub fn mulv(v1: Self, v2: Self) callconv(.Inline) Self {
			return Self {
				.vec = v1.vec * v2.vec,
			};
		}

		pub fn div(self: Self, factor: T) callconv(.Inline) Self {
			return Self {
				.vec = self.vec / @as(@Vector(4, T), @splat(factor)),
			};
		}

		pub fn len(self: Self) callconv(.Inline) T {
			return std.math.sqrt(self.len_squared());
		}

		pub fn len_squared(self: Self) callconv(.Inline) T {
			return self.dot(self);
		}

		pub fn normalize(self: Self) callconv(.Inline) Self {
			const l = self.len();
			return self.div(l);
		}

		pub fn reflectBy(self: Self, normal: Self) callconv(.Inline) Self {
			return self.sub(normal.mul(2 * self.dot(normal)));
		}

		pub fn refractBy(self: Self, normal: Self, rr: T) callconv(.Inline) Self {
			const cosTheta = @min(self.mul(-1).dot(normal), 1.0);
			const outPerp = self.add(normal.mul(cosTheta)).mul(rr);
			const outParallel = normal.mul(-std.math.sqrt(std.math.fabs(1.0 - outPerp.len_squared())));
			return outPerp.add(outParallel);
		}

		pub fn dot(v1: Self, v2: Self) callconv(.Inline) T {
			return v1.vec[0] * v2.vec[0] + v1.vec[1] * v2.vec[1] + v1.vec[2] * v2.vec[2];
		}

		pub fn cross(v1: Self, v2: Self) callconv(.Inline) Self {
			return Self {
				.vec = .{
					v1.vec[1] * v2.vec[2] - v1.vec[2] * v2.vec[1],
					v1.vec[2] * v2.vec[0] - v1.vec[0] * v2.vec[2],
					v1.vec[0] * v2.vec[1] - v1.vec[1] * v2.vec[0],
					0,
				},
			};
		}

		pub fn randomNormal() callconv(.Inline) Self {
			return random().normalize();
		}

		pub fn random() callconv(.Inline) Self {
			return init(
				rnd.rng.random().floatNorm(T),
				rnd.rng.random().floatNorm(T),
				rnd.rng.random().floatNorm(T)
			);
		}

		pub fn randomOnHemisphere(normal: Self) callconv(.Inline) Self {
			const randVec = randomNormal();
			return if (normal.dot(randVec) > 0) randVec else randVec.mul(-1);
		}
	};
}
