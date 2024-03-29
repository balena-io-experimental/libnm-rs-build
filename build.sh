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

if [ -d "libnm-rs-examples" ]
then
    rm -rf libnm-rs-examples
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

# Install with `pip install https://github.com/hay/xml2json/zipball/master`
echo -e "\e[1;36m[build] xml2json\e[0m"

xml2json -t xml2json --pretty --strip_text --strip_namespace --strip_newlines -o NM-1.0.json NM-1.0.gir

popd # gir-files

echo -e "\e[1;36m[build] generate-toml.py\e[0m"

../../generate-toml.py

# Add a symlink to compiled https://github.com/gtk-rs/gir
echo -e "\e[1;36m[build] gir sys\e[0m"

../../gir -d gir-files -c Gir_NM.sys.toml -o nm-sys

echo -e "\e[1;36m[build] gir src\e[0m"

../../gir -d gir-files -c Gir_NM.toml

echo -e "\e[1;36m[build] gir doc\e[0m"

../../gir -d gir-files -c Gir_NM.toml --doc-target-path docs.md -m doc

# Add a symlink to compiled https://github.com/GuillaumeGomez/rustdoc-stripper
echo -e "\e[1;36m[build] rustdoc-stripper\e[0m"

../../rustdoc-stripper -g -o docs.md

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

echo -e "\e[1;36m[build] git reset --hard\e[0m"

git reset --hard

echo -e "\e[1;36m[build] git fetch\e[0m"

git fetch

echo -e "\e[1;36m[build] git pull --rebase\e[0m"

git pull --rebase

echo -e "\e[1;36m[build] Move generated files\e[0m"

rm -rf src
rm -rf nm-sys
rm Cargo.toml

mv ../libnm-rs-gen/src .
mv ../libnm-rs-gen/nm-sys .
mv ../libnm-rs-gen/Cargo.toml .

echo -e "\e[1;36m[build] generate-toml.py --edition\e[0m"

../../generate-toml.py --edition

echo -e "\e[1;36m[build] cargo fmt\e[0m"

cargo fmt

echo -e "\e[1;36m[build] example connectivity\e[0m"

cargo run --example connectivity || true

echo -e "\e[1;36m[build] example list-connections\e[0m"

cargo run --example list-connections || true

echo -e "\e[1;36m[build] build access-point\e[0m"

cargo build --example access-point || true

echo -e "\e[1;36m[build] cargo clippy\e[0m"

cargo clippy || true

echo -e "\e[1;36m[build] git status\e[0m"

git status

popd # libnm-rs

popd # dist
