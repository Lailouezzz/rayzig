const std = @import("std");

pub const csdl = @cImport(@cInclude("SDL2/SDL.h"));

pub const SDL_Error = error{SDL_Error};

pub fn SDL_Init(flags: u32) !void {
	if (csdl.SDL_Init(flags) < 0) {
		return (SDL_Error.SDL_Error);
	}
}

pub fn SDL_Quit() void {
	csdl.SDL_Quit();
}

pub const SDL_Window = struct {
	const Self = @This();

	window: *csdl.SDL_Window = undefined,

	pub fn init(title: [*c]const u8, dimension: [2]c_int, flags: u32) !Self {
		std.log.info("Window: init with title \"{s}\", dimension {d}x{d}.", .{ title, dimension[0], dimension[1] });
		return Self{
			.window = if (csdl.SDL_CreateWindow(title,
				csdl.SDL_WINDOWPOS_CENTERED,
				csdl.SDL_WINDOWPOS_CENTERED,
				dimension[0], dimension[1], flags)) |w| w else return SDL_Error.SDL_Error};
	}

	pub fn deinit(self: Self) void {
		std.log.info("Window: deinit.", .{});
		csdl.SDL_DestroyWindow(self.window);
	}
};

pub const SDL_Renderer = struct {
	const Self = @This();

	renderer: *csdl.SDL_Renderer = undefined,

	pub fn init(window: SDL_Window, flags: u32) !Self {
		std.log.info("Renderer: init.", .{});
		return Self{
			.renderer = if (csdl.SDL_CreateRenderer(window.window,
				-1,
				flags)) |r| r else return SDL_Error.SDL_Error };
	}

	pub fn clear(self: Self) !void {
		if (csdl.SDL_RenderClear(self.renderer) < 0) {
			return SDL_Error.SDL_Error;
		}
	}

	pub fn copy(self: Self, texture: SDL_Texture) !void {
		if (csdl.SDL_RenderCopy(self.renderer, texture.texture, null, null) < 0) {
			return (SDL_Error.SDL_Error);
		}
	}

	pub fn present(self: Self) void {
		csdl.SDL_RenderPresent(self.renderer);
	}

	pub fn deinit(self: Self) void {
		std.log.info("Renderer: deinit.", .{});
		csdl.SDL_DestroyRenderer(self.renderer);
	}
};

pub const SDL_Texture = struct {
	const Self = @This();
	pub const FrameBuffer = struct {
		width: usize = undefined,
		height: usize = undefined,
		buffer: []u32 = undefined,
		allocator: std.mem.Allocator = undefined,

		pub fn init(width: usize, height: usize, allocator: std.mem.Allocator) !@This() {
			std.log.info("FrameBuffer: init for {d}x{d}.", .{ width, height });
			return FrameBuffer{
				.width = width,
				.height = height,
				.buffer = try allocator.alloc(u32, width * height),
				.allocator = allocator,
			};
		}

		pub fn clear(self: @This(), color: u32) void {
			@memset(self.buffer, color);
		}

		pub fn setPixel(self: @This(), x: usize, y: usize, color: u32) void {
			self.buffer[x + y * self.width] = color;
		}

		pub fn deinit(self: @This()) void {
			std.log.info("FrameBuffer: deinit.", .{});
			self.allocator.free(self.buffer);
		}
	};

	texture: *csdl.SDL_Texture = undefined,
	width: c_int = undefined,
	height: c_int = undefined,

	pub fn init(renderer: SDL_Renderer) SDL_Error!Self {
		var width: c_int = undefined;
		var height: c_int = undefined;

		std.log.info("Texture: init texture.", .{});
		if (csdl.SDL_GetRendererOutputSize(renderer.renderer, &width, &height) < 0) {
			return (SDL_Error.SDL_Error);
		}
		return Self{
			.texture = if (csdl.SDL_CreateTexture(renderer.renderer,
				csdl.SDL_PIXELFORMAT_ARGB8888,
				csdl.SDL_TEXTUREACCESS_STATIC,
				width, height)) |t| t else return SDL_Error.SDL_Error,
			.width = width,
			.height = height,
		};
	}

	pub fn update(self: Self, framebuffer: FrameBuffer) !void {
		if (csdl.SDL_UpdateTexture(self.texture, null, framebuffer.buffer.ptr, self.width * @sizeOf(u32)) < 0) {
			return SDL_Error.SDL_Error;
		}
	}

	pub fn genFrameBuffer(self: Self, allocator: std.mem.Allocator) !FrameBuffer {
		const width: usize = @as(c_uint, @bitCast(self.width));
		const height: usize = @as(c_uint, @bitCast(self.height));
		return FrameBuffer.init(width, height, allocator);
	}

	pub fn deinit(self: Self) void {
		std.log.info("Texture: deinit.", .{});
		csdl.SDL_DestroyTexture(self.texture);
	}
};
