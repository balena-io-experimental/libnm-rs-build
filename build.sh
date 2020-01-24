#!/usr/bin/env bash

set -e

if [ ! -d "dist" ]
then
    mkdir dist
fi

pushd dist

if [ -d "libnm-rs-gen" ]
then
    rm -rf libnm-rs-gen
fi

cp -r ../libnm-rs libnm-rs-gen

pushd libnm-rs-gen

mkdir gir-files

pushd gir-files

cp /usr/share/gir-1.0/Gio-2.0.gir .
cp /usr/share/gir-1.0/GObject-2.0.gir .
cp /usr/share/gir-1.0/GLib-2.0.gir .

../../../clean-gir.py

export PATH=$PATH:~/.local/bin

xml2json -t xml2json --pretty --strip_text --strip_namespace --strip_newlines -o NM-1.0.json NM-1.0.gir

popd # gir-files

../../generate-toml.py

../../gir -d gir-files -c Gir_NM.sys.toml -o nm-sys

../../gir -d gir-files -c Gir_NM.toml

rm -rf nm-sys/src/auto
rm -rf src/auto/versions.txt

../../merge-auto.py

cargo fmt

popd # libnm-rs-gen

if [ ! -d "libnm-rs" ]
then
    git clone git@github.com:balena-io-modules/libnm-rs.git
fi

pushd libnm-rs

git pull --rebase

rm -rf src
rm -rf nm-sys
rm -rf examples
rm Cargo.toml

mv ../libnm-rs-gen/src .
mv ../libnm-rs-gen/nm-sys .
mv ../libnm-rs-gen/examples .
mv ../libnm-rs-gen/Cargo.toml .

cargo run --example connectivity || true

cargo run --example connections || true

cargo clippy || true

git status

popd # libnm-rs

popd # dist
