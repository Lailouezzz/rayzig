const std = @import("std");

const sdl = @import("sdl.zig");
const rayzig = @import("rayzig.zig");

pub fn main() !void {
	var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
	defer arena.deinit();
	const allocator = arena.allocator();
	const rayzigCtx = rayzig.RayzigCtx.init(allocator) catch |err| {
		switch (err) {
			sdl.SDL_Error.SDL_Error => std.log.err("SDL Error: {s}", .{sdl.csdl.SDL_GetError()}),
			else => std.log.err("Error: {}", .{err}),
		}
		return err;
	};
	_ = rayzigCtx;
	// for (0..40) |x| {
	// 	fb.setPixel(x, 10, 0);
	// }
	// while (true) {
	// 	try texture.update(fb);
	// 	try renderer.clear();
	// 	try renderer.copy(texture);
	// 	renderer.present();
	// 	var event: sdl.csdl.SDL_Event = undefined;
	// 	_ = sdl.csdl.SDL_WaitEvent(&event);
	// 	switch (event.type) {
	// 		sdl.csdl.SDL_QUIT => break,
	// 		else => {},
	// 	}
	// }
}
