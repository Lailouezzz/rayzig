const std = @import("std");

const math = @import("math");
const Hittable = @import("../hittable.zig").Hittable;
const Ray = @import("../ray.zig").Ray;

const Self = @This();

hittableList: std.ArrayList(Hittable) = undefined,
allocator: std.mem.Allocator = undefined,

pub fn hittable(self: *Self) Hittable {
	return Hittable {
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

fn doesHit(ctx: *anyopaque, ray: Ray) ?Ray.Hit {
	const self: *Self = @ptrCast(@alignCast(ctx));
	var nearest: math.vector.FloatType = std.math.inf(math.vector.FloatType);
	var rec: ?Ray.Hit = null;
	
	for (self.hittableList.items) |object| {
		if (object.doesHit(ray)) |hit| {
			if (hit.t < nearest) {
				nearest = hit.t;
				rec = hit;
			}
		}
	}
	return rec;
}

pub fn printInfo(ctx: *anyopaque) !void {
	const self: *Self = @ptrCast(@alignCast(ctx));

	for (self.hittableList.items) |object| {
		try object.printInfo();
	}
}

pub fn create(allocator: std.mem.Allocator) !*Self {
	std.log.info("World: create.", .{});

	const pobject = try allocator.create(Self);
	errdefer allocator.destroy(pobject);
	pobject.* = Self {
		.hittableList = std.ArrayList(Hittable).init(allocator),
		.allocator = allocator,
	};
	return pobject;
}

pub fn destroy(self: *Self) void {
	for (self.hittableList.items) |object| {
		object.destroy();
	}
	self.hittableList.deinit();
	self.allocator.destroy(self);

	std.log.info("World: destroyed.", .{});
}

pub fn append(self: *Self, object: Hittable) !void {
	try self.hittableList.append(object);
}
