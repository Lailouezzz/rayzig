const std = @import("std");

const math = @import("math");
const Material = @import("../material.zig").Material;
const Ray = @import("../ray.zig").Ray;

const vector = math.vector;

const Self = @This();

albelo: vector.Color3f,
allocator: std.mem.Allocator,

pub fn material(self: *Self) Material {
	return Material {
		.ptr = self,
		.vtable = &.{
			.scatter = scatter,
			.attenuation = attenuation ,
			.destroy = struct {
				fn _destroy(ctx: *anyopaque) void {
					@as(*Self, @ptrCast(@alignCast(ctx))).destroy();
				}
			}._destroy,
		},
	};
}

pub fn create(albelo: vector.Color3f, allocator: std.mem.Allocator) !*Self {
	std.log.info("Material: Matal: create.", .{});

	const pobject = try allocator.create(Self);
	errdefer allocator.destroy(pobject);
	pobject.* = Self {
		.albelo = albelo,
		.allocator = allocator,
	};
	return pobject;
}

pub fn destroy(self: *Self) void {
	self.allocator.destroy(self);

	std.log.info("Material: Metal: destroyed.", .{});
}

fn scatter(ctx: *anyopaque, hit: Ray.Hit) ?Ray {
	const self = @as(*Self, @ptrCast(@alignCast(ctx)));

	_ = self;
	return Ray.init(hit.p, hit.fromDir.reflectBy(hit.normal));
}

fn attenuation(ctx: *anyopaque, hit: Ray.Hit) math.vector.Color3f {
	const self = @as(*Self, @ptrCast(@alignCast(ctx)));

	_ = hit;
	return self.albelo;
}
