const std = @import("std");

const sdl = @import("sdl");
const math = @import("math");

const vector = math.vector;
const World = @import("hittable.zig").World;
const Ray = math.ray.Ray;

const Self = @This();
const Camera = Self;

pos: vector.Point3f = undefined,
dir: vector.Vector3f = undefined,

pub fn init() Self {
	return Self {
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
		const viewport_height = 4.0;
		const viewport_width = viewport_height * (@as(vector.Coord, @floatFromInt(fb.width)) / @as(vector.Coord, @floatFromInt(fb.height)));

		const viewport_u = vector.Vector3f.init(viewport_width, 0, 0);
		const viewport_v = vector.Vector3f.init(0, -viewport_height, 0);

		const delta_u = viewport_u.div(@as(vector.Coord, @floatFromInt(fb.width)));
		const delta_v = viewport_v.div(@as(vector.Coord, @floatFromInt(fb.height)));

		std.log.info("Camera: Viewport = {d:.3}x{d:.3}.", .{viewport_width, viewport_height});
		std.log.info("Camera: Delta pixel u = {any} | v = {any}.", .{delta_u, delta_v});

		return @This() {
			.delta_u = delta_u,
			.delta_v = delta_v,
			.pixel00 = camera.pos.sub(vector.Vector3f.init(0, 0, focal_len)).sub(viewport_u.div(2)).sub(viewport_v.div(2)).add(delta_u.add(delta_v).div(2)),
			.center = camera.pos,
			.world = world,
			.fb = fb,
		};
	}

	fn _renderGetColor(self: @This()) u32 {
		_ = self;
	}

	pub fn render(self: @This()) !void {
		std.log.info("Camera: Center = {any}.", .{self.center});
		for (self.world.hittableList.items) |hittable| {
			try hittable.printInfo();
		}
		for (0..self.fb.height) |y| {
			// std.log.info("Camera: gen line {d}.", .{y});
			for (0..self.fb.width) |x| {
				const pixel_center = self.pixel00.add(self.delta_u.mul(@floatFromInt(x))).add(self.delta_v.mul(@floatFromInt(y)));
				const dir = pixel_center.sub(self.center);
				const ray = Ray.init(self.center, dir);
				for (self.world.hittableList.items) |hittable| {
					if (hittable.doesHit(ray)) |_| {
						self.fb.setPixel(x, y, sdl.Color.init(255, 0, 255).mul(1).asU32());
					}
				}
			}
		}
	}
};

pub fn render(self: Self, world: *World, fb: *sdl.SDL_Texture.FrameBuffer) !void {
	try Renderer.init(self, world, fb).render();
}
