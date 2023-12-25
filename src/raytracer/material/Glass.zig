const std = @import("std");

const math = @import("math");
const Material = @import("../material.zig").Material;
const Ray = @import("../ray.zig").Ray;

const vector = math.vector;

const Self = @This();

albelo: vector.Color3f,
ir: vector.FloatType,
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

pub fn create(albelo: vector.Color3f, ir: vector.FloatType, allocator: std.mem.Allocator) !*Self {
	std.log.info("Material: Glass: create.", .{});

	const pobject = try allocator.create(Self);
	errdefer allocator.destroy(pobject);
	pobject.* = Self {
		.albelo = albelo,
		.ir = ir,
		.allocator = allocator,
	};
	return pobject;
}

pub fn destroy(self: *Self) void {
	self.allocator.destroy(self);

	std.log.info("Material: Glass: destroyed.", .{});
}

fn scatter(ctx: *anyopaque, hit: Ray.Hit) ?Ray {
	const self = @as(*Self, @ptrCast(@alignCast(ctx)));

	const rr = if (hit.frontFace) 1 / self.ir else self.ir;

	const normalDir = hit.fromDir.normalize();
	const cosTheta = @min(normalDir.mul(-1).dot(hit.normal), 1.0);
	const sinTheta = std.math.sqrt(1.0 - cosTheta * cosTheta);

	const canRefract = rr * sinTheta < 1.0;

	return if (canRefract or reflectance(cosTheta, rr) < math.random.rng.random().float(vector.FloatType)) Ray.init(hit.p, normalDir.refractBy(hit.normal, rr))
		else Ray.init(hit.p, normalDir.reflectBy(hit.normal));
}

fn reflectance(cosine: vector.FloatType, rr: vector.FloatType) vector.FloatType{
	const r0 = (1 - rr) / (1 + rr);
	return r0 * r0 + (1 - r0 * r0) * std.math.pow(vector.FloatType, 1 - cosine, 5);
}

fn attenuation(ctx: *anyopaque, hit: Ray.Hit) math.vector.Color3f {
	const self = @as(*Self, @ptrCast(@alignCast(ctx)));

	_ = hit;
	return self.albelo;
}
