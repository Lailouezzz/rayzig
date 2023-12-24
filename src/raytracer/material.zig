const math = @import("math");

const Ray = math.ray.Ray;

pub const Material = struct {
	const Self = @This();

	ptr: *anyopaque,
	vtable: *const VTable,

	pub const VTable = struct {
		scatter: *const fn (ctx: *anyopaque, hit: Ray.Hit) ?Ray,
		attenuation: *const fn (ctx: *anyopaque, hit: Ray.Hit) math.vector.Color3f,
	};

	pub fn scatter(self: Self, hit: Ray.Hit) ?Ray {
		return self.vtable.scatter(self.ptr, hit);
	}

	pub fn attenuation(self: Self, hit: Ray.Hit) math.vector.Color3f {
		return self.vtable.attenuation(self.ptr, hit);
	}
};
