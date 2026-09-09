# manosaba-live2d

A minimal end-to-end Live2D demo for Godot 4. It uses
[gd_cubism](https://github.com/MizunagiKB/gd_cubism) v0.9.1,
Live2D Cubism SDK for Native 5-r.5, and the official Nijiiro Mao sample model.

## Run

Open `project.godot` with Godot 4.3 or newer, or run:

```bash
/Applications/Godot_mono.app/Contents/MacOS/Godot --path /Users/pakholeung/web/manosaba-live2d
```

The model starts with its idle motion. Move the pointer to control its gaze, use
the controls on the right to play motions/expressions, or press Space to play a
random motion.

![Successful Live2D render](artifacts/smoke-test.png)

Run the automated integration check with:

```bash
/Applications/Godot_mono.app/Contents/MacOS/Godot \
  --path /Users/pakholeung/web/manosaba-live2d \
  --script res://tests/smoke_test.gd
```

## Layout

- `addons/gd_cubism/` — compiled GDExtension and shaders used at runtime
- `assets/live2d/mao/` — local sample model runtime files
- `main.gd` / `main.tscn` — the integration demo

The editable plugin source lives in the sibling checkout
`/Users/pakholeung/web/gd_cubism`; this demo does not vendor a second copy.

## Rebuild the macOS arm64 addon

The Live2D SDK is proprietary and must be downloaded separately. Place or
extract `CubismSdkForNative-5-r.5` under
`/Users/pakholeung/web/gd_cubism/thirdparty`, then run:

```bash
cd /Users/pakholeung/web/gd_cubism
git submodule update --init --recursive
python3 -m venv .venv
.venv/bin/python -m pip install scons==4.7.0
.venv/bin/scons platform=macos arch=arm64 target=template_debug -j8
rsync -a --delete demo/addons/gd_cubism/ \
  /Users/pakholeung/web/manosaba-live2d/addons/gd_cubism/
```

### SDK 5-r.5 compatibility note

The sibling `gd_cubism` checkout has been adapted to the breaking renderer,
motion, expression, and blend-mode API changes in 5-r.5. Both Cubism Core and
Cubism Framework now come from SDK 5-r.5; `godot-cpp` remains pinned to the
Godot 4.3 stable commit `fbbf9ec4`.

This combination was compiled and run successfully with Godot 4.7.2 Mono on
macOS arm64. The 5-r.5 extended blend modes that do not have corresponding
GDCubism shaders currently fall back to normal blending. Distribution is
subject to the licenses in gd_cubism, the Live2D SDK, and the sample model's
`ReadMe.txt`.
