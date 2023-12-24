const std = @import("std");

const math = @import("math");

pub const Lambertian = @import("material/Lambertian.zig");
pub const Metal = @import("material/Metal.zig");

const Ray = @import("ray.zig").Ray;

pub const MaterialMap = struct {
	const Self = @This();

	materialMap: std.StringHashMap(Material),
	allocator: std.mem.Allocator = undefined,

	pub fn init(allocator: std.mem.Allocator) Self {
		return Self {
			.materialMap = std.StringHashMap(Material).init(allocator),
			.allocator = allocator,
		};
	}

	pub fn deinit(self: *Self) void {
		var it = self.materialMap.iterator();
		while (it.next()) |material| {
			material.value_ptr.destroy();
		}
		self.materialMap.deinit();
	}

	pub fn addMaterial(self: *Self, key: []const u8, material: Material) !void {
		try self.materialMap.put(key, material);
	}

	pub fn getMaterial(self: Self, key: []const u8) ?Material {
		return self.materialMap.get(key);
	}
};

pub const Material = struct {
	const Self = @This();

	ptr: *anyopaque,
	vtable: *const VTable,

	pub const VTable = struct {
		scatter: *const fn (ctx: *anyopaque, hit: Ray.Hit) ?Ray,
		attenuation: *const fn (ctx: *anyopaque, hit: Ray.Hit) math.vector.Color3f,
		destroy: *const fn (ctx: *anyopaque) void,
	};

	pub fn scatter(self: Self, hit: Ray.Hit) ?Ray {
		return self.vtable.scatter(self.ptr, hit);
	}

	pub fn attenuation(self: Self, hit: Ray.Hit) math.vector.Color3f {
		return self.vtable.attenuation(self.ptr, hit);
	}

	pub fn destroy(self: Self) void {
		self.vtable.destroy(self.ptr);
	}
};
