const std = @import("std");
const Io = std.Io;

const zqtfb = @import("zqtfb");

const doomgeneric = @cImport(@cInclude("doomgeneric.h"));
const keys = @cImport(@cInclude("doomkeys.h"));

var client: zqtfb.Client = undefined;
const width = 640;
const height = 400;
var clock: Io.Clock = undefined;
var io: Io = undefined;
var env: std.process.Environ = undefined;
var start_time: std.Io.Timestamp = undefined;
var inited = false;

const log = std.log.scoped(.doom_remarkable);

const Keys = enum(c_int) {
    up = keys.KEY_UPARROW,
    down = keys.KEY_DOWNARROW,
    left = keys.KEY_LEFTARROW,
    right = keys.KEY_RIGHTARROW,
    use = keys.KEY_USE,
    fire = keys.KEY_FIRE,
    enter = keys.KEY_ENTER,
    esc = keys.KEY_ESCAPE,
};

const Controller = @import("Controller.zig").Controller(Keys);
var controller: Controller = undefined;
const Key = Controller.Key;
const key_color: [4]u8 = .{ 255, 255, 255, 255 };
const key_pressed: [4]u8 = .{ 127, 127, 127, 255 };

var key_buffer: [16]Key = undefined;
var key_w_idx: usize = 0;
var key_r_idx: usize = 0;

fn addKey(kk: ?Key) void {
    if (kk) |k| {
        key_buffer[key_w_idx] = k;
        key_w_idx = (key_w_idx + 1) % key_buffer.len;
    }
}

fn getKey() ?Key {
    if (key_w_idx == key_r_idx) return null;
    const k = key_buffer[key_r_idx];
    key_r_idx = (key_r_idx + 1) % key_buffer.len;
    return k;
}

pub fn main(init: std.process.Init) !void {
    io = init.io;
    clock = .awake;
    env = init.minimal.environ;

    start_time = clock.now(io);
    log.info("Starting doom-remarkable at {d}", .{start_time});

    doomgeneric.doomgeneric_Create(
        @intCast(init.minimal.args.vector.len),
        @ptrCast(@constCast(init.minimal.args.vector.ptr)),
    );

    log.info("doomgenetic_Create successfully ran", .{});

    while (true) {
        doomgeneric.doomgeneric_Tick();
        // log.debug("doomgeneric_Tick", .{});

        if (!inited) continue;
        const s = client.pollServerPacket(io) catch {
            continue;
        };

        if (s.type == .user_input) {
            const x: usize = @intCast(s.message.input.x);
            const y: usize = @intCast(s.message.input.y);
            const finger_id = s.message.input.device_id;

            switch (s.message.input.type) {
                .touch_release => {
                    const key = controller.release(x, y, finger_id);
                    addKey(key);
                },
                .touch_press => {
                    const key = controller.press(x, y, finger_id);
                    addKey(key);
                },
                .pen_release => {
                    client.deinit(io);
                    std.process.exit(0);
                },
                else => {},
            }
        }
    }
}

export fn DG_Init() callconv(.c) void {
    const src = @src();
    log.debug("{s}: {s} {d}:{d}", .{ src.file, src.fn_name, src.line, src.column });

    const fb = zqtfb.getIDFromAppLoad(env) catch |err| {
        log.err("Unable to grab QTFB_KEY: {}", .{err});
        std.process.exit(1);
    };

    const device = zqtfb.Device.getDevice(io) catch |err| {
        log.err("Unable to determine device type: {}", .{err});
        std.process.exit(5);
    };

    const fb_type: zqtfb.Message.FramebufferType = switch (device) {
        .rM2 => .rM2_fb,
        .rMPP => .rMPP_rgba8888,
        .rMPPM => .rMPPM_rgba8888,
        .rMPPure => .rMPPure_rgba8888,
    };

    client = zqtfb.Client.init(
        io,
        fb,
        fb_type,
        .{ .width = width, .height = height },
        true,
    ) catch |err| {
        log.err("Unable to create QTFB client: {}", .{err});
        std.process.exit(2);
    };

    client.setRefreshMode(io, .animate) catch |err| {
        log.err("Unable to set animate refresh mode: {}", .{err});
        client.deinit(io);
        std.process.exit(3);
    };

    controller = Controller.init(client.width, client.height, client.getBPS());

    const btn_size = 50;

    const dpad_x = 25 + btn_size;
    const dpad_y = client.height - btn_size * 3 - 25;

    const action_x = client.width - 75 - 25 - btn_size - 25;
    const action_y = client.height - 75 - 25 - btn_size - 25;

    // dpad
    controller.addButton(dpad_x, dpad_y, btn_size, btn_size, .up, key_color, key_pressed);
    controller.addButton(dpad_x - btn_size, dpad_y + btn_size, btn_size, btn_size, .left, key_color, key_pressed);
    controller.addButton(dpad_x + btn_size, dpad_y + btn_size, btn_size, btn_size, .right, key_color, key_pressed);
    controller.addButton(dpad_x, dpad_y + btn_size * 2, btn_size, btn_size, .down, key_color, key_pressed);

    // esc
    controller.addButton(25, 25, btn_size, btn_size, .esc, key_color, key_pressed);

    // action pad
    controller.addButton(action_x + 25 + btn_size, action_y, btn_size, btn_size, .use, key_color, key_pressed);
    controller.addButton(action_x + 25 + btn_size, action_y + btn_size + 25, 75, 75, .fire, key_color, key_pressed);
    controller.addButton(action_x, action_y + btn_size + 25, btn_size, btn_size, .enter, key_color, key_pressed);

    client.fullUpdate(io) catch |err| {
        log.warn("Full screen update failed, continuing: {}", .{err});
    };

    inited = true;
}

export fn DG_GetKey(pressed: [*c]c_int, key: [*c]c_char) callconv(.c) c_int {
    const src = @src();
    log.debug("{s}: {s} {d}:{d}", .{ src.file, src.fn_name, src.line, src.column });

    if (getKey()) |k| {
        pressed.* = @intFromBool(k.pressed);
        key.* = @intCast(@intFromEnum(k.key));
        return 1;
    }

    return 0;
}

// noop
export fn DG_SetWindowTitle(title: [*]c_char) callconv(.c) void {
    const src = @src();
    log.debug("{s}: {s} {d}:{d}", .{ src.file, src.fn_name, src.line, src.column });
    _ = title; // autofix
}

export fn DG_DrawFrame() callconv(.c) void {
    const src = @src();
    log.debug("{s}: {s} {d}:{d}", .{ src.file, src.fn_name, src.line, src.column });
    var buffer: [width * height * 4]u8 = undefined;
    const bps = client.getBPS();

    for (0..height) |h| {
        for (0..width) |w| {
            // ScreenBuffer: BGRA (or possibly ARGB, just flipped)
            // rM:           RGBA
            const i = client.getPixel(@intCast(w), @intCast(h));
            const p: [4]u8 = @bitCast(doomgeneric.DG_ScreenBuffer[i / bps]);

            buffer[i] = p[2]; // R
            buffer[i + 1] = p[1]; // G
            buffer[i + 2] = p[0]; // B
            buffer[i + 3] = 255; // A
        }
    }

    controller.drawController(&buffer);
    @memcpy(client.display, &buffer);

    log.debug("Copied DG_ScreenBuffer to client.shm", .{});

    client.fullUpdate(io) catch |err| {
        log.warn("Full screen update failed, continuing: {}", .{err});
    };
}

export fn DG_SleepMs(ms: u32) callconv(.c) void {
    const src = @src();
    log.debug("{s}: {s} {d}:{d}", .{ src.file, src.fn_name, src.line, src.column });

    std.Io.sleep(io, .fromMilliseconds(ms), clock) catch unreachable;
}

export fn DG_GetTicksMs() callconv(.c) u32 {
    const src = @src();
    log.debug("{s}: {s} {d}:{d}", .{ src.file, src.fn_name, src.line, src.column });

    const diff = start_time.untilNow(io, clock);
    const d: u64 = @intCast(diff.toMilliseconds());

    return @truncate(d);
}
