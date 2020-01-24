#!/usr/bin/env bash

set -e

if [ ! -d "build" ]
then
    mkdir build
fi

if [ -d "build/libnm-rs" ]
then
    if [ -d "build/libnm-rs/target" ]
    then
        mv build/libnm-rs/target build
    fi

    rm -rf build/libnm-rs
fi

cp -r libnm-rs build

pushd build/libnm-rs

if [ -d "../target" ]
then
    mv ../target .
fi

mkdir gir-files

pushd gir-files

cp /usr/share/gir-1.0/Gio-2.0.gir .
cp /usr/share/gir-1.0/GObject-2.0.gir .
cp /usr/share/gir-1.0/GLib-2.0.gir .

../../../clean-gir.py

export PATH=$PATH:~/.local/bin

xml2json -t xml2json --pretty --strip_text --strip_namespace --strip_newlines -o NM-1.0.json NM-1.0.gir

popd

../../generate-toml.py

../../gir -d gir-files -c Gir_NM.sys.toml -o nm-sys

../../gir -d gir-files -c Gir_NM.toml

../../merge-auto.py

cargo fmt

RUST_BACKTRACE=1 cargo run --example connectivity || true

RUST_BACKTRACE=1 cargo run --example connections || true

popd
