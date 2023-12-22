const std = @import("std");

const sdl = @import("sdl");
const config = @import("config.zig");

const math = @import("math");
const rt = @import("raytracer");

const World = rt.hittable.World;
const Camera = rt.Camera;

pub const RayzigCtx = struct {
	const Self = @This();

	window: sdl.SDL_Window = undefined,
	renderer: sdl.SDL_Renderer = undefined,
	texture: sdl.SDL_Texture = undefined,
	framebuffer: sdl.SDL_Texture.FrameBuffer = undefined,
	camera: Camera = undefined,
	world: World = undefined,

	allocator: std.mem.Allocator = undefined,

	pub fn init(allocator: std.mem.Allocator) !Self {
		try sdl.SDL_Init(sdl.csdl.SDL_INIT_VIDEO);
		errdefer sdl.SDL_Quit();
		const window = try sdl.SDL_Window.init(config.window.title, config.window.dimension, 0);
		errdefer window.deinit();
		const renderer = try sdl.SDL_Renderer.init(window, 0);
		errdefer renderer.deinit();
		const texture = try sdl.SDL_Texture.init(renderer);
		errdefer texture.deinit();
		const fb = try texture.genFrameBuffer(allocator);
		errdefer fb.deinit();
		fb.clear(sdl.Color.init(255, 0, 0).asU32());
		return Self {
			.window = window,
			.renderer = renderer,
			.texture = texture,
			.framebuffer = fb,
			.camera = Camera.init(),
			.world = World.init(allocator),
			.allocator = allocator,
		};
	}

	pub fn run(self: *Self) anyerror!void {
		var is_running: bool = true;
		var event: sdl.csdl.SDL_Event = undefined;

		try self.world.append(rt.hittable.Sphere.init(math.vector.Point3f.init(0, 0, 0), 20));
		try self.world.append(rt.hittable.Sphere.init(math.vector.Point3f.init(0, 0, 0), 40));
		try self.world.append(rt.hittable.Sphere.init(math.vector.Point3f.init(0, 0, 0), 40));
		try self.world.append(rt.hittable.Sphere.init(math.vector.Point3f.init(0, 0, 0), 40));
		try self.world.append(rt.hittable.Sphere.init(math.vector.Point3f.init(0, 0, 0), 40));
		try self.world.append(rt.hittable.Sphere.init(math.vector.Point3f.init(0, 0, 0), 40));
		try self.world.append(rt.hittable.Sphere.init(math.vector.Point3f.init(0, 0, 0), 400));
		try self.world.append(rt.hittable.Sphere.init(math.vector.Point3f.init(0, 0, 0), 40));
		try self.world.append(rt.hittable.Sphere.init(math.vector.Point3f.init(0, 0, 0), 40));
		try self.world.hittable().printInfo();
		try self.camera.render(&self.world, &self.framebuffer);
		while (is_running) {
			while (sdl.csdl.SDL_PollEvent(&event) == 1)
			{
				switch (event.type) {
					sdl.csdl.SDL_QUIT => is_running = false,
					else => {},
				}
			}
			try self.texture.update(self.framebuffer);
			try self.renderer.clear();
			try self.renderer.copy(self.texture);
			self.renderer.present();
		}
	}

	pub fn deinit(self: Self) void {
		self.world.deinit();
		self.framebuffer.deinit();
		self.texture.deinit();
		self.renderer.deinit();
		self.window.deinit();
		sdl.SDL_Quit();
	}
};
