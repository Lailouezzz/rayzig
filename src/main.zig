const std = @import("std");

const sdl = @import("sdl");
const rayzig = @import("rayzig.zig");

pub fn main() !void {
	var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
	defer arena.deinit();
	const allocator = arena.allocator();
	// const allocator = std.heap.c_allocator;
	var rayzigCtx = rayzig.RayzigCtx.init(allocator) catch |err| {
		switch (err) {
			sdl.SDL_Error.SDL_Error => std.log.err("SDL Error: {s}", .{sdl.csdl.SDL_GetError()}),
			else => std.log.err("Error: {}", .{err}),
		}
		return err;
	};
	defer rayzigCtx.deinit();
	rayzigCtx.run() catch |err| {
		switch (err) {
			sdl.SDL_Error.SDL_Error => std.log.err("SDL Error: {s}", .{sdl.csdl.SDL_GetError()}),
			else => std.log.err("Error: {}", .{err}),
		}
		return err;
	};
}
