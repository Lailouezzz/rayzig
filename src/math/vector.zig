const std = @import("std");

pub const Vector3f32 = Vector3(f64);

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

		pub fn len(self: Self) T {
			return std.math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
		}

		pub fn normalize(self: Self) Self {
			const l = self.len();
			return Self {
				.x = self.x / l,
				.y = self.y / l,
				.z = self.z / l,
			};
		}

		pub fn dot(v1: Self, v2: Self) T {
			return v1.x * v2.x + v1.y * v2.y + v1.z + v2.z;
		}

		pub fn cross(v1: Self, v2: Self) Self {
			return Self {
				.x = v1.y * v2.z - v1.z * v2.y,
				.y = v1.z * v2.x - v1.x * v2.z,
				.z = v1.x * v2.y - v1.y * v2.x,
			};
		}
	};
}
