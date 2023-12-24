const std = @import("std");

const math = @import("math");
const Hittable = @import("../hittable.zig").Hittable;

const vector = math.vector;
const Ray = math.ray.Ray;

const Self = @This();

center: vector.Point3f,
radius: vector.FloatType,
allocator: std.mem.Allocator,

pub fn hittable(self: *Self) Hittable {
	return Hittable{
		.ptr = self,
		.vtable = &.{
			.doesHit = doesHit,
			.printInfo = printInfo,
			.destroy = struct {
				fn _destroy(ctx: *anyopaque) void {
					@as(*Self, @ptrCast(@alignCast(ctx))).destroy();
				}
			}._destroy,
		},
	};
}

pub fn create(center: vector.Point3f, radius: vector.FloatType, allocator: std.mem.Allocator) !*Self {
	std.log.info("Sphere: create.", .{});

	const pobject = try allocator.create(Self);
	errdefer allocator.destroy(pobject);
	pobject.* = Self{
		.center = center,
		.radius = radius,
		.allocator = allocator,
	};
	return pobject;
}

pub fn destroy(self: *Self) void {
	self.allocator.destroy(self);

	std.log.info("Sphere: destroyed.", .{});
}

pub fn doesHit(ctx: *anyopaque, ray: Ray) ?Ray.Hit {
	const self: *Self = @ptrCast(@alignCast(ctx));

	const oc = ray.orig.sub(self.center);
	const a = ray.dir.len_squared();
	const half_b = oc.dot(ray.dir);
	const c = oc.len_squared() - self.radius * self.radius;
	const discriminant = half_b * half_b - a * c;

	if (discriminant < 0)
		return null;
	var root = (-half_b - std.math.sqrt(discriminant)) / a;
	if (root < 0) {
		root = (-half_b + std.math.sqrt(discriminant)) / a;
	}
	if (root < 0.001) return null;
	return Ray.Hit.init(ray, root, ray.at(root).sub(self.center).normalize(), ray.at(root));
}

pub fn printInfo(ctx: *anyopaque) !void {
	const self: *Self = @ptrCast(@alignCast(ctx));

	std.log.info("Sphere: center = {} | radius = {d:.4}.", .{ self.center, self.radius });
}
