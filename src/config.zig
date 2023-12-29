pub const window = struct {
	pub const title = "rayzig";
	pub const dimension = [2]c_int{1920, 1080};
};
pub const threadCount = 16;
pub const sampleCount = 8192;
pub const maxRayBounce = 70;
pub const defaultFov = 35;
