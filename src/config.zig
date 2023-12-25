pub const window = struct {
	pub const title = "rayzig";
	pub const dimension = [2]c_int{1920/2, 1080/2};
};
pub const threadCount = 12;
pub const sampleCount = 1024;
pub const maxRayBounce = 30;
pub const defaultFov = 20;
