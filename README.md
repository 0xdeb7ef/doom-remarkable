# doom-remarkable

DOOM port to the reMarkable tablet, based on [doomgeneric](https://github.com/ozkl/doomgeneric). Uses [ztqfb](https://github.com/0xdeb7ef/zqtfb) under the hood to talk to [AppLoad](https://github.com/asivery/rm-appload).

## Build

Use `zig build` to build it.

*Debug builds are broken, so use the ReleaseFast builds.*
You may specify the device to target with `-Ddevice`:

```
zig build -Drelease=true -Ddevice=ferrari
```

*Refer to [zig-remarkable](https://github.com/0xdeb7ef/zig-remarkable) for target options.*

## Install
Copy `zig-out/doom-remarkable` onto your tablet in `~/xovi/exthome/appload/doom-remarkable`.

You also need `.wad` files to play.
