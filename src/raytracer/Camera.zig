const std = @import("std");

const sdl = @import("sdl");
const math = @import("math");
const config = @import("config");

const vector = math.vector;
const World = @import("hittable.zig").World;
const Ray = math.ray.Ray;

const Self = @This();
const Camera = Self;

pos: vector.Point3f = undefined,
dir: vector.Vector3f = undefined,

pub fn init() Self {
	return Self{
		.pos = vector.Point3f.init(0, 0, 0),
		.dir = vector.Point3f.init(0, 0, 1),
	};
}

const Renderer = struct {
	delta_u: vector.Vector3f = undefined,
	delta_v: vector.Vector3f = undefined,
	pixel00: vector.Point3f = undefined,
	center: vector.Point3f = undefined,
	world: *World = undefined,
	fb: *sdl.SDL_Texture.FrameBuffer = undefined,

	pub fn init(camera: Camera, world: *World, fb: *sdl.SDL_Texture.FrameBuffer) @This() {
		const focal_len = 1.0;
		const viewport_height = 2.0;
		const viewport_width = viewport_height * (@as(vector.FloatType, @floatFromInt(fb.width)) / @as(vector.FloatType, @floatFromInt(fb.height)));

		const viewport_u = vector.Vector3f.init(viewport_width, 0, 0);
		const viewport_v = vector.Vector3f.init(0, -viewport_height, 0);

		const delta_u = viewport_u.div(@as(vector.FloatType, @floatFromInt(fb.width)));
		const delta_v = viewport_v.div(@as(vector.FloatType, @floatFromInt(fb.height)));

		const viewport_upper_left = camera.pos.add(vector.Vector3f.init(0, 0, focal_len)).sub(viewport_u.div(2)).sub(viewport_v.div(2));

		std.log.info("Renderer: Viewport = {d:.3}x{d:.3}.", .{ viewport_width, viewport_height });
		std.log.info("Renderer: Delta pixel u = {any} | v = {any}.", .{ delta_u, delta_v });

		return @This(){
			.delta_u = delta_u,
			.delta_v = delta_v,
			.pixel00 = viewport_upper_left.add(delta_u.add(delta_v).div(2)),
			.center = camera.pos,
			.world = world,
			.fb = fb,
		};
	}

	pub fn render(self: *@This(), sampleCount: u32) !void {
		for (0..self.fb.height) |y| {
			// std.log.info("Camera: gen line {d}.", .{y});
			for (0..self.fb.width) |x| {
				const pixelCenter = self.pixel00.add(self.delta_u.mul(@floatFromInt(x))).add(self.delta_v.mul(@floatFromInt(y)));

				var colors: vector.Color3f = vector.Color3f.init(0, 0, 0);
				for (0..sampleCount) |_| {
					const pixelSample = pixelCenter.add(self._randomInSquare());
					const dir = pixelSample.sub(self.center);
					const ray = Ray.init(self.center, dir);
					
					colors = colors.add(self._rayColor(ray, config.maxRayBounce));
				}
				colors = colors.div(@floatFromInt(sampleCount));
				self.fb.setPixel(x, y, _toRawColor(colors).asU32());
			}
		}
	}

	fn _randomInSquare(self: *@This()) vector.Point3f {
		const rng = math.random.rng.random();

		return self.delta_u.mul(rng.float(vector.FloatType) - 0.5).add(
			self.delta_v.mul(rng.float(vector.FloatType) - 0.5)
		);
	}

	fn _toRawColor(color: vector.Color3f) sdl.Color {
		return (sdl.Color.init(
			@intFromFloat(std.math.clamp(color.x, 0, 1) * 255),
			@intFromFloat(std.math.clamp(color.y, 0, 1) * 255),
			@intFromFloat(std.math.clamp(color.z, 0, 1) * 255)));
	}

	fn _rayColor(self: @This(), ray: Ray, depth: u16) vector.Color3f {
		if (depth == 0) return vector.Color3f.init(0, 0, 0);
		const hittableWorld = self.world.hittable();
		if (hittableWorld.doesHit(ray)) |hit| {
			const dir = vector.Vector3f.randomOnHemisphere(hit.normal).add(hit.normal);
			return self._rayColor(Ray.init(hit.p, dir), depth - 1).mul(0.5);
		}
		const a = 0.5 * (ray.dir.normalize().y + 1);
		return vector.Color3f.init(1, 1, 1).mul(1 - a).add(
				vector.Color3f.init(0.5, 0.7, 1).mul(a));
	}
};

pub fn render(self: Self, world: *World, fb: *sdl.SDL_Texture.FrameBuffer, sampleCount: u32) !void {
	var renderer = Renderer.init(self, world, fb);
	try renderer.render(sampleCount);
}
