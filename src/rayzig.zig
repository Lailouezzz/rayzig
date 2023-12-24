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
	world: *World = undefined,

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
		fb.clear(sdl.Color.init(20, 20, 20).asU32());
		const world = try World.create(allocator);
		errdefer world.destroy();
		try world.append((try rt.hittable.Sphere.create(math.vector.Point3f.init(0, 0, 3), 1, allocator)).hittable());
		//try world.append((try rt.hittable.Sphere.create(math.vector.Point3f.init(10, 0, 10), 1, allocator)).hittable());
		return Self {
			.window = window,
			.renderer = renderer,
			.texture = texture,
			.framebuffer = fb,
			.camera = Camera.init(),
			.world = world,
			.allocator = allocator,
		};
	}

	pub fn run(self: *Self) anyerror!void {
		var is_running: bool = true;
		var event: sdl.csdl.SDL_Event = undefined;

		while (is_running) {
			while (sdl.csdl.SDL_PollEvent(&event) == 1) {
				switch (event.type) {
					sdl.csdl.SDL_QUIT => is_running = false,
					else => {},
				}
			}
			const theSphere = @as(*rt.hittable.Sphere, @ptrCast(@alignCast(self.world.hittableList.items[0].ptr)));
			theSphere.radius += 0.01;
			self.framebuffer.clear(sdl.Color.init(20, 20, 20).asU32());
			const tStart = std.time.milliTimestamp();
			try self.camera.render(self.world, &self.framebuffer);
			const deltaTime = std.time.milliTimestamp() - tStart;
			std.log.info("Frame time: {d}.", .{deltaTime});
			try self.texture.update(self.framebuffer);
			try self.renderer.clear();
			try self.renderer.copy(self.texture);
			self.renderer.present();
		}
	}

	pub fn deinit(self: Self) void {
		self.world.destroy();
		self.framebuffer.deinit();
		self.texture.deinit();
		self.renderer.deinit();
		self.window.deinit();
		sdl.SDL_Quit();
	}
};
