const std = @import("std");

const math = @import("math");
const Hittable = @import("../hittable.zig").Hittable;

const Ray = math.ray.Ray;

const Self = @This();

hittableList: std.ArrayList(Hittable) = undefined,
allocator: std.mem.Allocator = undefined,

pub fn hittable(self: *Self) Hittable {
	return Hittable {
		.ptr = self,
		.vtable = &.{
			.doesHit = doesHit,
			.printInfo = printInfo,
			.deinit = deinit,
		},
	};
}

pub fn doesHit(ctx: *anyopaque, ray: Ray) ?Ray.Hit {
	_ = ctx;
	_ = ray;
	return null;
}

pub fn printInfo(ctx: *anyopaque) !void {
	const self: *Self = @ptrCast(@alignCast(ctx));

	for (self.hittableList.items) |object| {
		try object.printInfo();
	}
}

pub fn init(allocator: std.mem.Allocator) Self {
	return Self {
		.hittableList = std.ArrayList(Hittable).init(allocator),
		.allocator = allocator,
	};
}

pub fn deinit(ctx: *anyopaque) void {
	const self: *Self = @ptrCast(@alignCast(ctx));

	for (self.hittableList.items) |object| {
		object.deinit();
	}
	self.hittableList.deinit();
}

pub fn append(self: *Self, object: anytype) !void {
	comptime {
		if (!std.meta.hasFn(@TypeOf(object), "hittable"))
			@compileError("object must have init fn.");
	}
	var pobject = try self.allocator.create(@TypeOf(object));
	errdefer self.allocator.destroy(pobject);
	pobject.* = object;
	try self.hittableList.append(pobject.hittable());
}
