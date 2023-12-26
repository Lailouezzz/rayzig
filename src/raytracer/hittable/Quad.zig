const std = @import("std");

const math = @import("math");
const Hittable = @import("../hittable.zig").Hittable;
const Material = @import("../material.zig").Material;
const Ray = @import("../ray.zig").Ray;

const vector = math.vector;

const Self = @This();

pos: vector.Point3f,
normal: vector.Vector3f,
D: vector.FloatType,
w: vector.Vector3f,
u: vector.Vector3f,
v: vector.Vector3f,
allocator: std.mem.Allocator,
mat: Material,

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

pub fn create(pos: vector.Point3f, u: vector.Vector3f, v: vector.Vector3f, mat: Material, allocator: std.mem.Allocator) !*Self {
	std.log.info("Quad: create.", .{});

	const pobject = try allocator.create(Self);
	errdefer allocator.destroy(pobject);
	pobject.* = brk: {
		const n = u.cross(v);
		const normal = n.normalize();
		break :brk Self {
			.pos = pos,
			.normal = normal,
			.D = normal.dot(pos),
			.w = n.div(n.len_squared()),
			.u = u,
			.v = v,
			.allocator = allocator,
			.mat = mat,
		};
	};
	return pobject;
}

pub fn destroy(self: *Self) void {
	self.allocator.destroy(self);

	std.log.info("Quad: destroyed.", .{});
}

fn doesHit(ctx: *anyopaque, ray: Ray) ?Ray.Hit {
	const self: *Self = @ptrCast(@alignCast(ctx));

	const denom = self.normal.dot(ray.dir);
	if (std.math.fabs(denom) <= 1e-8)
		return null;
	
	const t = (self.D - ray.orig.dot(self.normal)) / denom;
	if (t < 0.001)
		return null;

	const planeHitPt = ray.at(t).sub(self.pos);
	const planeV = self.w.dot(planeHitPt.cross(self.v));
	const planeU = self.w.dot(self.u.cross(planeHitPt));

	if (planeV < 0 or planeV > 1 or planeU < 0 or planeU > 1)
		return null;

	return Ray.Hit.init(ray, t, self.normal, self.mat);
}

fn printInfo(ctx: *anyopaque) !void {
	const self: *Self = @ptrCast(@alignCast(ctx));

	std.log.info("Quad: D = {d} | normal = {}.", .{ self.D, self.normal});
}
