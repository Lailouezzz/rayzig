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
		try materials.addMaterial("mat", (try material.Lambertian.create(math.vector.Color3f.init(0.7, 0.5, 0.8), allocator)).material());
		try materials.addMaterial("light", (try material.Light.create(math.vector.Color3f.init(19, 12, 12), allocator)).material());
		try materials.addMaterial("basic_metal", (try material.Metal.create(math.vector.Color3f.init(1, 1, 1), 0.1, allocator)).material());
		try materials.addMaterial("perfect_metal", (try material.Metal.create(math.vector.Color3f.init(0.94, 0.98, 0.94), 0.0005, allocator)).material());
		try materials.addMaterial("basic_glass", (try material.Glass.create(math.vector.Color3f.init(0.9, 0.91, 0.9), 1.51821, allocator)).material());
		const world = try World.create(allocator);
		errdefer world.destroy();
		try world.append((try rt.hittable.Sphere.create(math.vector.Point3f.init(-1, 1, 1.5), 0.5, materials.getMaterial("basic_glass").?, allocator)).hittable());
		try world.append((try rt.hittable.Sphere.create(math.vector.Point3f.init(-1, 1, 1.5), -0.4, materials.getMaterial("basic_glass").?, allocator)).hittable());
		try world.append((try rt.hittable.Sphere.create(math.vector.Point3f.init(0, 0, 1.5), 0.5, materials.getMaterial("mat").?, allocator)).hittable());
		try world.append((try rt.hittable.Sphere.create(math.vector.Point3f.init(1, 0, 1.5), 0.5, materials.getMaterial("basic_metal").?, allocator)).hittable());
		try world.append((try rt.hittable.Sphere.create(math.vector.Point3f.init(0, 6, 1.5), 0.3, materials.getMaterial("light").?, allocator)).hittable());
		try world.append((try rt.hittable.Quad.create(math.vector.Point3f.init(-3, 16, 6), math.vector.Vector3f.init(200, 0, 0), math.vector.Vector3f.init(0, -16.5, 0), materials.getMaterial("perfect_metal").?, allocator)).hittable());
		try world.append((try rt.hittable.Quad.create(math.vector.Point3f.init(-3, 16, 0), math.vector.Vector3f.init(200, 0, 0), math.vector.Vector3f.init(0, -16.5, 0), materials.getMaterial("perfect_metal").?, allocator)).hittable());
		try world.append((try rt.hittable.Quad.create(math.vector.Point3f.init(-2, 1.1, 2.4), math.vector.Vector3f.init(0, 0, 0.5), math.vector.Vector3f.init(0, -0.5, 0), materials.getMaterial("light").?, allocator)).hittable());
		try world.append((try rt.hittable.Quad.create(math.vector.Point3f.init(-3, 16, 0), math.vector.Vector3f.init(0, 0, 6), math.vector.Vector3f.init(0, -16.5, 0), materials.getMaterial("mat").?, allocator)).hittable());
		try world.append((try rt.hittable.Quad.create(math.vector.Point3f.init(-3, -0.5, 0), math.vector.Vector3f.init(200, 0, 0), math.vector.Vector3f.init(0, 0, 6), materials.getMaterial("ground").?, allocator)).hittable());
		// try world.append((try rt.hittable.Sphere.create(math.vector.Point3f.init(0, -1000.5, 1.5), 1000, materials.getMaterial("ground").?, allocator)).hittable());
		return Self {
			.window = window,
			.renderer = renderer,
			.texture = texture,
			.framebuffer = fb,
			.camera = Camera.init(config.defaultFov, math.vector.Point3f.init(1.5, 1.5, 5.9), math.vector.Vector3f.init(0.5, 0.5, 1.5)),
			.world = world,
			.materials = materials,
			.allocator = allocator,
		};
	}

	fn updateFrame(self: *Self) !void {
		try std.io.getStdOut().writer().print("Rayzig: starting frame renderer.\n", .{});
		const tStart = std.time.milliTimestamp();
		try self.camera.render(self.world, &self.framebuffer, config.sampleCount, config.threadCount, self.allocator);
		const deltaTime = std.time.milliTimestamp() - tStart;
		try std.io.getStdOut().writer().print("Rayzig: Frame time: {d}.\n", .{deltaTime});
	}

	pub fn run(self: *Self) anyerror!void {
		var buf: [1024]u8 = undefined;
		var is_running: bool = true;
		var event: sdl.csdl.SDL_Event = undefined;

		self.framebuffer.clear(sdl.Color.init(0, 0, 0).asU32());
		while (is_running) {
			std.time.sleep(1000000 * 16);
			try self.texture.update(self.framebuffer);
			try self.renderer.copy(self.texture);
			self.renderer.present();
			while (sdl.csdl.SDL_PollEvent(&event) == 1) {
				switch (event.type) {
					sdl.csdl.SDL_QUIT => is_running = false,
					sdl.csdl.SDL_KEYDOWN => {
						if (event.key.keysym.scancode == sdl.csdl.SDL_SCANCODE_R) _ = try std.Thread.spawn(.{}, updateFrame, .{self});
						if (event.key.keysym.scancode == sdl.csdl.SDL_SCANCODE_S) try self.renderer.saveBMP(self.texture, std.fmt.bufPrintZ(&buf, "renderer{d}.bmp", .{std.time.milliTimestamp()}) catch "render.bmp");
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
