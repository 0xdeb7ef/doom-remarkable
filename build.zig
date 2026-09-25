const std = @import("std");

const remarkable = @import("zig_remarkable");

const name = "doom-remarkable";

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseFast,
    });
    const device = b.option(
        remarkable.Device,
        "device",
        "reMarkable device to target (default: ferrari",
    ) orelse .ferrari;

    const target = b.standardTargetOptions(.{
        .default_target = remarkable.query(device),
    });

    const zqtfb = b.dependency("zqtfb", .{}).module("zqtfb");
    const doomgeneric = b.dependency("doomgeneric", .{});

    const exe = b.addExecutable(.{
        .name = name,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .imports = &.{
                .{ .name = "zqtfb", .module = zqtfb },
            },
            .strip = switch (optimize) {
                .ReleaseFast, .ReleaseSmall => true,
                else => null,
            },
        }),
    });

    exe.root_module.addIncludePath(doomgeneric.path("doomgeneric"));
    exe.root_module.addCSourceFiles(.{ .files = &c_sources, .root = doomgeneric.path("doomgeneric"), .flags = &.{"-fno-sanitize=all"} });

    const doom = b.addInstallArtifact(exe, .{
        .dest_dir = .{
            .override = .{
                .custom = name,
            },
        },
    });

    const manifest = b.addInstallFileWithDir(
        b.path("assets/manifest.json"),
        .{ .custom = name },
        "external.manifest.json",
    );

    b.getInstallStep().dependOn(&doom.step);
    b.getInstallStep().dependOn(&manifest.step);
}

const c_sources = [_][]const u8{
    "am_map.c",
    "d_event.c",
    "d_items.c",
    "d_iwad.c",
    "d_loop.c",
    "d_main.c",
    "d_mode.c",
    "d_net.c",
    "doomdef.c",
    "doomgeneric.c",
    "doomstat.c",
    "dstrings.c",
    "dummy.c",
    "f_finale.c",
    "f_wipe.c",
    "g_game.c",
    "gusconf.c",
    "hu_lib.c",
    "hu_stuff.c",
    "i_cdmus.c",
    "icon.c",
    "i_endoom.c",
    "i_input.c",
    "i_joystick.c",
    "info.c",
    "i_scale.c",
    "i_sound.c",
    "i_system.c",
    "i_timer.c",
    "i_video.c",
    "m_argv.c",
    "m_bbox.c",
    "m_cheat.c",
    "m_config.c",
    "m_controls.c",
    "memio.c",
    "m_fixed.c",
    "m_menu.c",
    "m_misc.c",
    "m_random.c",
    "mus2mid.c",
    "p_ceilng.c",
    "p_doors.c",
    "p_enemy.c",
    "p_floor.c",
    "p_inter.c",
    "p_lights.c",
    "p_map.c",
    "p_maputl.c",
    "p_mobj.c",
    "p_plats.c",
    "p_pspr.c",
    "p_saveg.c",
    "p_setup.c",
    "p_sight.c",
    "p_spec.c",
    "p_switch.c",
    "p_telept.c",
    "p_tick.c",
    "p_user.c",
    "r_bsp.c",
    "r_data.c",
    "r_draw.c",
    "r_main.c",
    "r_plane.c",
    "r_segs.c",
    "r_sky.c",
    "r_things.c",
    "sha1.c",
    "sounds.c",
    "s_sound.c",
    "statdump.c",
    "st_lib.c",
    "st_stuff.c",
    "tables.c",
    "v_video.c",
    "w_checksum.c",
    "w_file.c",
    "w_file_stdc.c",
    "wi_stuff.c",
    "w_main.c",
    "w_wad.c",
    "z_zone.c",
};
