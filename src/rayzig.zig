const std = @import("std");

const sdl = @import("sdl");
const config = @import("config");

const math = @import("math");
const rt = @import("raytracer");

const World = rt.hittable.World;
const material = rt.material;
const Camera = rt.Camera;

pub const RayzigCtx = struct {
	const Self = @This();

	window: sdl.SDL_Window = undefined,
	renderer: sdl.SDL_Renderer = undefined,
	texture: sdl.SDL_Texture = undefined,
	framebuffer: sdl.SDL_Texture.FrameBuffer = undefined,
	camera: Camera = undefined,
	world: *World = undefined,
	materials: material.MaterialMap = undefined,

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
		var materials = material.MaterialMap.init(allocator);
		errdefer materials.deinit();
		try materials.addMaterial("ground", (try material.Lambertian.create(math.vector.Color3f.init(0.6, 0.5, 0.6), allocator)).material());
		try materials.addMaterial("mat", (try material.Lambertian.create(math.vector.Color3f.init(0.5, 0.5, 0.5), allocator)).material());
		try materials.addMaterial("light", (try material.Light.create(math.vector.Color3f.init(8, 8, 8), allocator)).material());
		try materials.addMaterial("basic_metal", (try material.Metal.create(math.vector.Color3f.init(1, 1, 1), 0.3, allocator)).material());
		try materials.addMaterial("basic_glass", (try material.Glass.create(math.vector.Color3f.init(1, 1, 1), 1.2, allocator)).material());
		const world = try World.create(allocator);
		errdefer world.destroy();
		try world.append((try rt.hittable.Sphere.create(math.vector.Point3f.init(-1, 1, 1.5), 0.5, materials.getMaterial("basic_glass").?, allocator)).hittable());
		try world.append((try rt.hittable.Sphere.create(math.vector.Point3f.init(0, 0, 1.5), 0.5, materials.getMaterial("mat").?, allocator)).hittable());
		try world.append((try rt.hittable.Sphere.create(math.vector.Point3f.init(1, 0, 1.5), 0.5, materials.getMaterial("basic_metal").?, allocator)).hittable());
		try world.append((try rt.hittable.Sphere.create(math.vector.Point3f.init(0, 3.5, 1.5), 1, materials.getMaterial("light").?, allocator)).hittable());
		try world.append((try rt.hittable.Sphere.create(math.vector.Point3f.init(0, -1000.5, 1.5), 1000, materials.getMaterial("ground").?, allocator)).hittable());
		return Self {
			.window = window,
			.renderer = renderer,
			.texture = texture,
			.framebuffer = fb,
			.camera = Camera.init(config.defaultFov, math.vector.Point3f.init(8, 4, 8), math.vector.Vector3f.init(0, 0, 1.5)),
			.world = world,
			.materials = materials,
			.allocator = allocator,
		};
	}

	fn updateFrame(self: *Self) !void {
		self.framebuffer.clear(sdl.Color.init(0, 0, 0).asU32());
		const tStart = std.time.milliTimestamp();
		try self.camera.render(self.world, &self.framebuffer, config.sampleCount, config.threadCount, self.allocator);
		const deltaTime = std.time.milliTimestamp() - tStart;
		std.log.info("Frame time: {d}.", .{deltaTime});
		try self.texture.update(self.framebuffer);
		try self.renderer.clear();
	}

	pub fn run(self: *Self) anyerror!void {
		var is_running: bool = true;
		var event: sdl.csdl.SDL_Event = undefined;

		while (is_running) {
			try self.renderer.copy(self.texture);
			self.renderer.present();
			while (sdl.csdl.SDL_PollEvent(&event) == 1) {
				switch (event.type) {
					sdl.csdl.SDL_QUIT => is_running = false,
					sdl.csdl.SDL_KEYDOWN => {
						if (event.key.keysym.scancode == sdl.csdl.SDL_SCANCODE_R) try self.updateFrame();
					},
					else => {},
				}
			}
		}
	}

	pub fn deinit(self: *Self) void {
		self.world.destroy();
		self.materials.deinit();
		self.framebuffer.deinit();
		self.texture.deinit();
		self.renderer.deinit();
		self.window.deinit();
		sdl.SDL_Quit();
	}
};
