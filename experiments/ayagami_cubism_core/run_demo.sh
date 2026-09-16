#!/bin/zsh
set -euo pipefail

experiment_dir=${0:A:h}
demo_dir=${experiment_dir:h:h}
gd_cubism_dir=${demo_dir:h}/gd_cubism
godot_bin=${GODOT_BIN:-/Applications/Godot_mono.app/Contents/MacOS/Godot}
shim_archive=${experiment_dir}/target/debug/libayagami_cubism_core.a
gd_binary_rel=demo/addons/gd_cubism/bin/libgd_cubism.macos.debug.framework/libgd_cubism.macos.debug
demo_binary=${demo_dir}/addons/gd_cubism/bin/libgd_cubism.macos.debug.framework/libgd_cubism.macos.debug
temporary_dir=$(mktemp -d /tmp/ayagami-cubism-core-demo.XXXXXX)

restore_binaries() {
  if [[ -f ${temporary_dir}/gd_cubism ]]; then
    cp ${temporary_dir}/gd_cubism ${gd_cubism_dir}/${gd_binary_rel}
  fi
  if [[ -f ${temporary_dir}/demo ]]; then
    cp ${temporary_dir}/demo ${demo_binary}
  fi
  rm -rf ${temporary_dir}
}
trap restore_binaries EXIT INT TERM

cp ${gd_cubism_dir}/${gd_binary_rel} ${temporary_dir}/gd_cubism
cp ${demo_binary} ${temporary_dir}/demo

cd ${experiment_dir}
cargo build

cd ${gd_cubism_dir}
rm -f ${gd_cubism_dir}/${gd_binary_rel}
CUBISM_CORE_LIBRARY=${shim_archive} \
  .venv/bin/scons platform=macos arch=arm64 target=template_debug -j8
cp ${gd_cubism_dir}/${gd_binary_rel} ${demo_binary}

cd ${demo_dir}
${godot_bin} --path ${demo_dir} res://main.tscn
