//! Controller function that returns a Controller type.

/// Returns a Controller type.
pub fn Controller(
    /// Pass an enum of the keys you will be using.
    comptime KeyType: type,
) type {
    const max_buttons = @typeInfo(KeyType).@"enum".fields.len;
    return struct {
        const Self = @This();

        var screen_width: usize = undefined;
        var screen_height: usize = undefined;
        var screen_bps: usize = undefined;

        buttons: [max_buttons]Button = undefined,
        idx: usize = 0,

        /// Initializes the Controller with the screen width, height, and bits per pixel.
        ///
        /// This is required for internal coordinate to pixel index calculations.
        pub fn init(width: usize, height: usize, bps: usize) Self {
            screen_width = width;
            screen_height = height;
            screen_bps = bps;

            return Self{};
        }

        /// Creates and adds a Button to the list that this controller manages.
        pub fn addButton(
            self: *Self,
            x: usize,
            y: usize,
            w: usize,
            h: usize,
            key: KeyType,
            color: [4]u8,
            color_pressed: [4]u8,
        ) void {
            if (self.idx > max_buttons) unreachable;

            self.buttons[self.idx] = .{
                .x = x,
                .y = y,
                .w = w,
                .h = h,
                .key = .{ .key = key },
                .color = color,
                .color_pressed = color_pressed,
            };
            self.idx += 1;
        }

        /// Draws the controller to the buffer provided via `display`.
        pub fn drawController(self: Self, display: []u8) void {
            for (self.buttons[0..self.idx]) |btn| {
                drawRect(
                    display,
                    btn.x,
                    btn.y,
                    btn.w,
                    btn.h,
                    if (btn.key.pressed) btn.color_pressed else btn.color,
                );
            }
        }

        fn drawRect(buffer: []u8, x: usize, y: usize, w: usize, h: usize, color: [4]u8) void {
            for (x..x + w) |col| {
                for (y..y + h) |row| {
                    const i = getPixel(col, row);
                    buffer[i] = color[0]; // R
                    buffer[i + 1] = color[1]; // G
                    buffer[i + 2] = color[2]; // B
                    buffer[i + 3] = 255; // A
                }
            }
        }

        fn touch(self: *Self, x: usize, y: usize) ?*Button {
            for (&self.buttons) |*btn| {
                if (x >= btn.x and
                    x <= btn.x + btn.w and
                    y >= btn.y and
                    y <= btn.y + btn.h)
                {
                    return btn;
                }
            }

            return null;
        }

        /// Handles a touch press event by checking if the touch coordinates hit a button.
        /// Returns the key of the pressed button if successful, otherwise returns null.
        pub fn press(self: *Self, x: usize, y: usize, finger_id: i32) ?Key {
            if (touch(self, x, y)) |btn| {
                btn.key.finger_id = finger_id;
                btn.key.pressed = true;
                return btn.key;
            }

            return null;
        }

        /// Release the button associated with a specific `finger_id`.
        /// Currently ignores x and y coordinates.
        pub fn release(self: *Self, x: usize, y: usize, finger_id: i32) ?Key {
            _ = x; // autofix
            _ = y; // autofix
            for (&self.buttons) |*btn| {
                if (btn.key.finger_id == finger_id) {
                    btn.key.pressed = false;
                    return btn.key;
                }
            }
            return null;
        }

        /// TODO - No real use found yet. Does nothing right now.
        pub fn update(self: *Self, x: usize, y: usize, finger_id: i32) ?Key {
            _ = self; // autofix
            _ = x; // autofix
            _ = y; // autofix
            _ = finger_id; // autofix
            return null;
        }

        /// Represents if a key is pressed or not, as well as which key it was.
        ///
        /// `finger_id` is mainly for internal use.
        pub const Key = struct {
            pressed: bool = false,
            key: KeyType,
            finger_id: i32 = 0,
        };

        const Button = struct {
            x: usize,
            y: usize,
            w: usize,
            h: usize,

            key: Key,
            color: [4]u8,
            color_pressed: [4]u8,
        };

        fn getPixel(x: usize, y: usize) usize {
            return (y * screen_width + x) * screen_bps;
        }
    };
}
