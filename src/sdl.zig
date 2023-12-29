const std = @import("std");

pub const csdl = @cImport({
	@cInclude("SDL2/SDL.h");
	@cInclude("SDL2/SDL_image.h");
});

pub const SDL_Error = error{SDL_Error};

pub fn SDL_Init(flags: u32) !void {
	if (csdl.SDL_Init(flags) < 0) {
		return (SDL_Error.SDL_Error);
	}
}

pub fn SDL_Quit() void {
	csdl.SDL_Quit();
}

pub const Color = packed struct {
	const Self = @This();
	b: u8 = undefined,
	g: u8 = undefined,
	r: u8 = undefined,
	a: u8 = 0,

	pub fn init(r: u8, g: u8, b: u8) Self {
		return Self {
			.r = r,
			.g = g,
			.b = b,
		};
	}

	pub fn mul(self: Self, factor: f32) Self {
		return Self {
			.b = @intFromFloat(@as(f32, @floatFromInt(self.b)) * factor),
			.g = @intFromFloat(@as(f32, @floatFromInt(self.g)) * factor),
			.r = @intFromFloat(@as(f32, @floatFromInt(self.r)) * factor),
			.a = @intFromFloat(@as(f32, @floatFromInt(self.a)) * factor),
		};
	}

	pub fn asU32(self: *const Self) u32 {
		return @as(*const u32, @ptrCast(self)).*;
	}
};

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

	pub fn copy(self: Self, texture: SDL_Texture) SDL_Error!void {
		if (csdl.SDL_RenderCopy(self.renderer, texture.texture, null, null) < 0) {
			return (SDL_Error.SDL_Error);
		}
	}

	pub fn saveBMP(self: Self, texture: SDL_Texture, filename: [*c]const u8) SDL_Error!void {
		defer std.log.info("Saved to BMP: \"{s}\".", .{filename});
		const target = csdl.SDL_GetRenderTarget(self.renderer);
		defer _ = csdl.SDL_SetRenderTarget(self.renderer, target);
		if (csdl.SDL_SetRenderTarget(self.renderer, texture.texture) < 0)
			return SDL_Error.SDL_Error;
		var w: c_int = undefined;
		var h: c_int = undefined;
		if (csdl.SDL_QueryTexture(texture.texture, null, null, &w, &h) < 0)
			return SDL_Error.SDL_Error;
		var surface = csdl.SDL_CreateRGBSurface(0, w, h, 32, 0, 0, 0, 0);
		defer csdl.SDL_FreeSurface(surface);
		if (surface == null)
			return SDL_Error.SDL_Error;
		if (csdl.SDL_RenderReadPixels(self.renderer, null, surface.*.format.*.format, surface.*.pixels,surface.*.pitch) < 0)
			return SDL_Error.SDL_Error;
		if (csdl.IMG_SavePNG(surface, filename) < 0)
			return SDL_Error.SDL_Error;
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

		pub fn setPixel(self: @This(), x: usize, y: usize, color: u32) callconv(.Inline) void {
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
				csdl.SDL_TEXTUREACCESS_TARGET,
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
