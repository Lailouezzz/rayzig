const math = @import("math");

const Ray = @import("ray.zig").Ray;

pub const Sphere = @import("hittable/Sphere.zig");
pub const Quad = @import("hittable/Quad.zig");
pub const World = @import("hittable/World.zig");

pub const Hittable = struct {
	const Self = @This();

	ptr: *anyopaque,
	vtable: *const VTable,

	pub const VTable = struct {
		doesHit: *const fn (ctx: *anyopaque, ray: Ray) ?Ray.Hit,
		printInfo: *const fn (ctx: *anyopaque) anyerror!void,
		destroy: *const fn (ctx: *anyopaque) void,
	};

	pub fn doesHit(self: Self, ray: Ray) callconv(.Inline) ?Ray.Hit {
		return self.vtable.doesHit(self.ptr, ray);
	}

	pub fn printInfo(self: Self) callconv(.Inline) !void {
		return self.vtable.printInfo(self.ptr);
	}

	pub fn destroy(self: Self) callconv(.Inline) void {
		self.vtable.destroy(self.ptr);
	}
};
