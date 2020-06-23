#!/usr/bin/env bash

set -e

echo -e "\e[1;36m[build] Building...\e[0m"

if [ ! -d "dist" ]
then
    mkdir dist
fi

pushd dist

if [ -d "libnm-rs-gen" ]
then
    rm -rf libnm-rs-gen
fi

echo -e "\e[1;36m[build] Copy libnm-rs to libnm-rs-gen\e[0m"

cp -r ../libnm-rs libnm-rs-gen

pushd libnm-rs-gen

mkdir gir-files

pushd gir-files

echo -e "\e[1;36m[build] Copy gir files\e[0m"

cp /usr/share/gir-1.0/Gio-2.0.gir .
cp /usr/share/gir-1.0/GObject-2.0.gir .
cp /usr/share/gir-1.0/GLib-2.0.gir .

echo -e "\e[1;36m[build] Clean gir\e[0m"

../../../clean-gir.py

export PATH=$PATH:~/.local/bin

echo -e "\e[1;36m[build] xml2json\e[0m"

xml2json -t xml2json --pretty --strip_text --strip_namespace --strip_newlines -o NM-1.0.json NM-1.0.gir

popd # gir-files

echo -e "\e[1;36m[build] generate-toml.py\e[0m"

../../generate-toml.py

echo -e "\e[1;36m[build] gir sys\e[0m"

../../gir -d gir-files -c Gir_NM.sys.toml -o nm-sys

echo -e "\e[1;36m[build] gir src\e[0m"

../../gir -d gir-files -c Gir_NM.toml

echo -e "\e[1;36m[build] gir doc\e[0m"

../../gir -d gir-files -c Gir_NM.toml --doc-target-path docs.md -m doc

echo -e "\e[1;36m[build] rustdoc-stripper\e[0m"

rustdoc-stripper -g -o docs.md

mv Cargo-sys.toml nm-sys/Cargo.toml

rm -rf nm-sys/src/auto
rm -rf src/auto/versions.txt

echo -e "\e[1;36m[build] merge-auto.py\e[0m"

../../merge-auto.py

popd # libnm-rs-gen

if [ ! -d "libnm-rs" ]
then
    git clone git@github.com:balena-io-modules/libnm-rs.git
fi

pushd libnm-rs

echo -e "\e[1;36m[build] git pull --rebase\e[0m"

git pull --rebase

echo -e "\e[1;36m[build] Move generated files\e[0m"

rm -rf src
rm -rf nm-sys
rm -rf examples
rm Cargo.toml

mv ../libnm-rs-gen/src .
mv ../libnm-rs-gen/nm-sys .
mv ../libnm-rs-gen/examples .
mv ../libnm-rs-gen/Cargo.toml .

echo -e "\e[1;36m[build] cargo fix --edition\e[0m"

cargo fix --edition --allow-dirty

echo -e "\e[1;36m[build] cargo fmt\e[0m"

cargo fmt

echo -e "\e[1;36m[build] generate-toml.py --edition\e[0m"

../../generate-toml.py --edition

echo -e "\e[1;36m[build] example connectivity\e[0m"

cargo run --example connectivity || true

echo -e "\e[1;36m[build] example connections\e[0m"

cargo run --example connections || true

echo -e "\e[1;36m[build] cargo clippy\e[0m"

cargo clippy || true

git status

popd # libnm-rs

popd # dist
