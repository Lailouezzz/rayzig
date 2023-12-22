const std = @import("std");

const math = @import("math");
const Hittable = @import("../hittable.zig").Hittable;

const vector = math.vector;
const Ray = math.ray.Ray;

const Self = @This();

center: vector.Point3f,
radius: vector.Coord,
allocator: std.mem.Allocator,

pub fn hittable(self: *Self) Hittable {
	return Hittable {
		.ptr = self,
		.vtable = &.{
			.doesHit = doesHit,
			.printInfo = printInfo,
		},
	};
}

pub fn init(center: vector.Point3f, radius: vector.Coord) Self {
	return Self {
		.center = center,
		.radius = radius,
	};
}

pub fn create(center: vector.Point3f, radius: vector.Coord) *Self {

}

pub fn doesHit(ctx: *anyopaque, ray: Ray) ?Ray.Hit {
	_ = ctx;
	_ = ray;
	return null;
}

pub fn printInfo(ctx: *anyopaque) !void {
	const self: *Self = @ptrCast(@alignCast(ctx));

	std.log.info("Sphere: center = {} | radius = {d:.4}.", .{self.center, self.radius});
}
