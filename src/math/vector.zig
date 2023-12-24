const std = @import("std");

const rng = &@import("random.zig").rng;

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

		x: T,
		y: T,
		z: T,

		pub fn init(x: T, y: T, z: T) Self {
			return Self {
				.x = x,
				.y = y,
				.z = z,
			};
		}

		pub fn add(v1: Self, v2: Self) Self {
			return Self {
				.x = v1.x + v2.x,
				.y = v1.y + v2.y,
				.z = v1.z + v2.z,
			};
		}

		pub fn sub(v1: Self, v2: Self) Self {
			return Self {
				.x = v1.x - v2.x,
				.y = v1.y - v2.y,
				.z = v1.z - v2.z,
			};
		}

		pub fn mul(self: Self, factor: T) Self {
			return Self {
				.x = self.x * factor,
				.y = self.y * factor,
				.z = self.z * factor,
			};
		}

		pub fn mulv(v1: Self, v2: Self) Self {
			return Self {
				.x = v1.x * v2.x,
				.y = v1.y * v2.y,
				.z = v1.z * v2.z,
			};
		}

		pub fn div(self: Self, factor: T) Self {
			return Self {
				.x = self.x / factor,
				.y = self.y / factor,
				.z = self.z / factor,
			};
		}

		pub fn len(self: Self) T {
			return std.math.sqrt(self.len_squared());
		}

		pub fn len_squared(self: Self) T {
			return self.x * self.x + self.y * self.y + self.z * self.z;
		}

		pub fn normalize(self: Self) Self {
			const l = self.len();
			return Self {
				.x = self.x / l,
				.y = self.y / l,
				.z = self.z / l,
			};
		}

		pub fn reflectBy(self: Self, normal: Self) Self {
			return self.sub(normal.mul(2 * self.dot(normal)));
		}

		pub fn dot(v1: Self, v2: Self) T {
			return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
		}

		pub fn cross(v1: Self, v2: Self) Self {
			return Self {
				.x = v1.y * v2.z - v1.z * v2.y,
				.y = v1.z * v2.x - v1.x * v2.z,
				.z = v1.x * v2.y - v1.y * v2.x,
			};
		}

		pub fn random() Self {
			return init(
				rng.random().float(T) * 2 - 1,
				rng.random().float(T) * 2 - 1,
				rng.random().float(T) * 2 - 1
			).normalize();
		}

		pub fn randomOnHemisphere(normal: Self) Self {
			const randVec = random();
			return if (normal.dot(randVec) > 0) randVec else randVec.mul(-1);
		}
	};
}
