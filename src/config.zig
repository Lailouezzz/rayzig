pub const window = struct {
	pub const title = "rayzig";
	pub const dimension = [2]c_int{1920/2, 1080/2};
};
pub const threadCount = 24;
pub const sampleCount = 256;
pub const maxRayBounce = 45;
pub const defaultFov = 35;
