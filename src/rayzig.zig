const std = @import("std");

const sdl = @import("sdl.zig");
const config = @import("config.zig");

pub const RayzigCtx = struct {
	const Self = @This();

	window: sdl.SDL_Window = undefined,
	renderer: sdl.SDL_Renderer = undefined,
	texture: sdl.SDL_Texture = undefined,
	framebuffer: sdl.SDL_Texture.FrameBuffer = undefined,

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
		return Self {
			.window = window,
			.renderer = renderer,
			.texture = texture,
			.framebuffer = fb,
			.allocator = allocator,
		};
	}

	pub fn deinit(self: Self) void {
		self.framebuffer.deinit();
		self.texture.deinit();
		self.renderer.deinit();
		self.window.deinit();
		sdl.SDL_Quit();
	}
};
