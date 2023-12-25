const std = @import("std");

const math = @import("math");
const Material = @import("../material.zig").Material;
const Ray = @import("../ray.zig").Ray;

const vector = math.vector;

const Self = @This();

power: vector.Vector3f,
allocator: std.mem.Allocator,

pub fn material(self: *Self) Material {
	return Material {
		.ptr = self,
		.vtable = &.{
			.scatter = scatter,
			.attenuation = attenuation,
			.emission = emission,
			.destroy = struct {
				fn _destroy(ctx: *anyopaque) void {
					@as(*Self, @ptrCast(@alignCast(ctx))).destroy();
				}
			}._destroy,
		},
	};
}

pub fn create(power: vector.Vector3f, allocator: std.mem.Allocator) !*Self {
	std.log.info("Material: Light: create.", .{});

	const pobject = try allocator.create(Self);
	errdefer allocator.destroy(pobject);
	pobject.* = Self {
		.power = power,
		.allocator = allocator,
	};
	return pobject;
}

pub fn destroy(self: *Self) void {
	self.allocator.destroy(self);

	std.log.info("Material: Light: destroyed.", .{});
}

fn scatter(ctx: *anyopaque, hit: Ray.Hit) ?Ray {
	_ = ctx;
	_ = hit;

	return null;
}

fn attenuation(ctx: *anyopaque, hit: Ray.Hit) math.vector.Color3f {
	_ = ctx;
	_ = hit;

	return math.vector.Color3f.init(0, 0, 0);
}

fn emission(ctx: *anyopaque, hit: Ray.Hit) math.vector.Color3f {
	const self = @as(*Self, @ptrCast(@alignCast(ctx)));

	_ = hit;
	return self.power;
}
