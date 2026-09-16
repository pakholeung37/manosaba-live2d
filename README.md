# manosaba-live2d

A minimal end-to-end Live2D demo for Godot 4, with two runtime paths:

- `main.tscn`: gd_cubism v0.9.1 + Live2D Cubism SDK for Native 5-r.5
- `ayagami_demo.tscn`: the open-source Ayagami Rust runtime

Both scenes use the local Nijiiro Mao sample model.

## Run

Open `project.godot` with Godot 4.7 or newer to run the gd_cubism scene, or
launch either implementation directly. The gd_cubism binary still targets the
Godot 4.3 ABI, but the bundled Ayagami extension requires Godot 4.7.

```bash
/Applications/Godot_mono.app/Contents/MacOS/Godot --path /Users/pakholeung/web/manosaba-live2d

/Applications/Godot_mono.app/Contents/MacOS/Godot \
  --path /Users/pakholeung/web/manosaba-live2d \
  res://ayagami_demo.tscn
```

The model starts with its idle motion. Move the pointer to control its gaze, use
the controls on the right to play motions/expressions, or press Space to play a
random motion.

### Ayagami demo

![Ayagami rendering the Mao model](artifacts/ayagami-smoke-test.png)

The Ayagami scene loads the `.model3.json` directly, creates its generated mesh,
mask, physics, motion, and expression controllers, and exposes motion/expression
controls through a regular Godot scene. Its integration follows the downstream
pattern used by `open-vt`.

On stock Godot 4.7.2 the copied addon uses the closest built-in blend modes.
Rendering works, but additive/multiplicative composition is not pixel-identical
to Ayagami's patched Godot build; the cyan highlights visible in the screenshot
are one consequence. Accurate Ayagami blending currently requires its custom
Godot 4.7 build or the corresponding upstream Godot blend-mode change.

### gd_cubism demo

![Successful gd_cubism render](artifacts/smoke-test.png)

Run both automated integration checks with:

```bash
/Applications/Godot_mono.app/Contents/MacOS/Godot \
  --path /Users/pakholeung/web/manosaba-live2d \
  --script res://tests/smoke_test.gd

/Applications/Godot_mono.app/Contents/MacOS/Godot \
  --path /Users/pakholeung/web/manosaba-live2d \
  --script res://tests/ayagami_smoke_test.gd
```

## Layout

- `addons/gd_cubism/` — compiled GDExtension and shaders used at runtime
- `addons/ayagami/` — Ayagami GDExtension, shaders, and macOS arm64 debug library
- `assets/live2d/mao/` — local sample model runtime files
- `main.gd` / `main.tscn` — the gd_cubism integration demo
- `ayagami_demo.gd` / `ayagami_demo.tscn` — the Ayagami integration demo
- `experiments/ayagami_cubism_core/` — Ayagami-backed Cubism Core C-ABI shim
  that runs the existing gd_cubism integration without ayagami-gd

## Ayagami through gd_cubism experiment

Ayagami is compatible with the MOC3 format and model behavior, but does not
currently expose the Cubism Core C ABI expected by the Cubism Native Framework
inside gd_cubism. The experiment supplies that missing ABI shim and has been
verified with the Mao model (128 parameters, 260 drawables, masks, motions, and
expressions):

```bash
cd experiments/ayagami_cubism_core
./run_experiment.sh
```

The script temporarily links gd_cubism against Ayagami, runs the Rust and Godot
checks, and restores the existing official-Core binaries afterward. See the
experiment README for its ownership and Cubism 5.3 offscreen limitations.

The editable gd_cubism source lives in the sibling checkout
`/Users/pakholeung/web/gd_cubism`; this demo does not vendor a second copy.

## Rebuild the macOS arm64 gd_cubism addon

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

The sibling `gd_cubism` checkout has been adapted to the breaking renderer,
motion, expression, and blend-mode API changes in 5-r.5. Both Cubism Core and
Cubism Framework now come from SDK 5-r.5; `godot-cpp` remains pinned to the
Godot 4.3 stable commit `fbbf9ec4`.

This combination was compiled and run successfully with Godot 4.7.2 Mono on
macOS arm64. The 5-r.5 extended blend modes that do not have corresponding
GDCubism shaders currently fall back to normal blending. Distribution is
subject to the licenses in gd_cubism, the Live2D SDK, and the sample model's
`ReadMe.txt`.

## Rebuild the macOS arm64 Ayagami addon

The debug library is built from the sibling checkouts
`/Users/pakholeung/web/ayagami-gd` and `/Users/pakholeung/web/ayagami`.
`ayagami-gd/Cargo.toml` uses the local path dependency
`../ayagami/ayagami`, so edits in either checkout are included by the next
Cargo build.

```bash
cd /Users/pakholeung/web/ayagami-gd
cargo build
cp target/debug/libayagami_gd.dylib \
  addons/ayagami/lib/libayagami_gd.debug.dylib
rsync -a --delete addons/ayagami/ \
  /Users/pakholeung/web/manosaba-live2d/addons/ayagami/
```

The local ayagami-gd checkout contains the macOS debug-library mapping and the
stock-Godot shader fallbacks (`blend_premul_alpha`, `blend_add`, and
`blend_mul`). Its binding code has also been updated from the removed
`sorted_artmeshes()` / `blend_mode()` APIs to the current Ayagami
`draw_nodes()` / `blend_config()` APIs. The copied addon retains the upstream
MIT license in `addons/ayagami/LICENSE.md`.
