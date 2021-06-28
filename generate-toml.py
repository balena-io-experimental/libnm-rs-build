#!/usr/bin/env python
# -*- coding: utf-8 -*-

import itertools
import json
import qtoml
import pkgconfig
import copy
import argparse

from collections import OrderedDict as odict
from operator import itemgetter

MANUAL = [
    'GObject.Object',
    'GLib.ByteArray',
    'GLib.Bytes',
    'GLib.FileTest',
    'GLib.Error',
    'GLib.KeyFile',
    'GLib.ObjectClass',
    'GLib.PtrArray',
    'GLib.Variant',
    'GLib.VariantType',
    'Gio.AsyncReadyCallback',
    'Gio.Cancellable',
    'Gio.DBusConnection',
    'Gio.DBusInterfaceInfo',
    'Gio.DBusMethodInvocation',
    'Gio.DBusObjectManagerClientFlags',
    'Gio.DBusProxy',
    'Gio.InputStream',
    'Gio.OutputStream',
]

def generate():
    nm_json = read_json('gir-files/NM-1.0.json')

    strip_namespaces(nm_json)

    namespace = nm_json['repository']['namespace']

    generate_nm_toml(namespace)

    versions = get_versions_list(namespace)

    meta = read_toml("../../meta.toml")

    generate_cargo_toml(meta, versions)
    generate_sys_cargo_toml(meta, versions)

def strip_namespaces(data):
    if type(data) == list:
        for value in data:
            strip_namespaces(value)

    if type(data) != dict:
        return

    keys = list(data.keys())

    for key in keys:
        pos = key.find('}')

        if pos == -1:
            continue

        new_key = '@' + key[pos + 1:]

        value = data.pop(key)

        data[new_key] = value

    for value in data.values():
        strip_namespaces(value)

def generate_nm_toml(namespace):
    names = extract_objects(namespace)
    names = ['*'] + names
    names = ['NM.{}'.format(name) for name in names]

    options = odict(
        girs_dir = "gir-files",
        library = "NM",
        version = "1.0",
        target_path = ".",
        work_mode = "normal",
        single_version_file = True,
        generate = names,
        manual = MANUAL,
    )

    contents = odict(
        options = options,
    )

    save_toml('Gir_NM.toml', contents)

def extract_objects(namespace):
    names = []

    add_names(namespace, 'bitfield', names)
    add_names(namespace, 'enumeration', names)
    add_names(namespace, 'class', names)
    add_names(namespace, 'record', names, filter_records)
    add_names(namespace, 'interface', names)
    add_names(namespace, 'callback', names)

    names.sort()

    return names

def add_names(namespaces, namespace_name, names, filter=None):
    namespace = namespaces[namespace_name]
    for entity in namespace:
        if type(entity) == str:
            continue

        if filter is not None:
            if not filter(entity):
                continue

        name = entity['@name']

        if name[0].isnumeric():
            name = '_' + name

        names.append(name)

def filter_records(entity):
    if '@is-gtype-struct-for' in entity:
        return False

    if entity.get('@disguised') == '1':
        return False

    return True

def generate_cargo_toml(meta, versions):
    contents = odict()

    add_package_cargo_toml(contents, meta)
    add_dependencies_cargo_toml(contents, meta)
    add_features_cargo_toml(contents, versions)

    save_toml("Cargo.toml", contents)

def add_package_cargo_toml(contents, meta):
    package = odict()
    package["name"] = "nm"
    package["version"] = meta["package"]["version"]
    package["authors"] = meta["package"]["authors"]
    contents["package"] = package
    package["edition"] = "2018"

def add_dependencies_cargo_toml(contents, meta):
    dependencies = copy.deepcopy(meta["dependencies"])

    ffi = odict()
    ffi["package"] = "nm-sys"
    ffi["path"] = "nm-sys"
    dependencies["ffi"] = ffi

    contents["dependencies"] = dependencies
    contents["dev-dependencies"] = meta["dev-dependencies"]

def add_features_cargo_toml(contents, versions):
    features = odict()

    previous = None
    for version in versions:
        current = "v{}_{}".format(version[0], version[1])

        current_list = ["ffi/" + current]
        if previous is not None:
            current_list.append(previous)
        features[current] = current_list
        previous = current

    features["default"] = [previous]

    contents["features"] = features

def generate_sys_cargo_toml(meta, versions):
    contents = odict()

    add_package_sys_cargo_toml(contents, meta)
    add_lib_sys_cargo_toml(contents, meta)
    add_dependencies_sys_cargo_toml(contents, meta)
    add_features_sys_cargo_toml(contents, versions)

    save_toml("Cargo-sys.toml", contents)

def add_package_sys_cargo_toml(contents, meta):
    package = odict()
    package["name"] = "nm-sys"
    package["version"] = meta["package"]["version"]
    package["authors"] = meta["package"]["authors"]
    package["links"] = '"nm"'
    package["edition"] = "2018"
    package["build"] = "build.rs"

    metadata = odict()
    metadata["docs"] = dict(rs = dict(features = ["dox"]))
    metadata["system-deps"] = dict(libnm = "1")
    package["metadata"] = metadata

    contents["package"] = package

def add_lib_sys_cargo_toml(contents, meta):
    lib = odict()
    lib["name"] = "nm_sys"
    contents["lib"] = lib

def add_dependencies_sys_cargo_toml(contents, meta):
    contents["dependencies"] = meta["sys-dependencies"]
    contents["build-dependencies"] = meta["sys-build-dependencies"]
    contents["dev-dependencies"] = meta["sys-dev-dependencies"]

def add_features_sys_cargo_toml(contents, versions):
    features = odict()

    previous = None
    for version in versions:
        current = "v{}_{}".format(version[0], version[1])

        current_list = []
        if previous is not None:
            current_list.append(previous)
        features[current] = current_list
        previous = current

    features["dox"] = []

    contents["features"] = features

def get_versions_list(namespace):
    libnm_version = minor_libnm_version()

    versions = set()

    for key, value in namespace.items():
        if isinstance(value, list):
            collect_versions(value, versions)

    versions = list(versions)
    versions = [version for version in versions if version <= libnm_version]
    versions.sort(key=itemgetter(1))

    return versions

def minor_libnm_version():
    version = pkgconfig.modversion('libnm')
    version = version.split('.')
    return (int(version[0]), int(version[1]))

def collect_versions(value, versions):
    if isinstance(value, dict):
        if '@version' in value:
            version = value['@version']
            version_tuple = to_version_tuple(version)
            versions.add(version_tuple)

        for key, inner in value.items():
            collect_versions(inner, versions)

    if isinstance(value, list):
        for inner in value:
            collect_versions(inner, versions)

def to_version_tuple(version):
    splitted = version.split('.')
    return (int(splitted[0]), int(splitted[1]))

def read_json(path):
    f = open(path, 'r')
    data = json.load(f)
    f.close()
    return data

def read_toml(path):
    f = open(path, 'r')
    data = qtoml.load(f)
    f.close()
    return data

def save_toml(path, contents):
    toml = qtoml.dumps(contents)
    f = open(path, 'w')
    f.write(toml)
    f.close()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--edition', action='store_true')
    args = parser.parse_args()
    if args.edition:
        include_edition()
    else:
        generate()

def include_edition():
    contents = read_toml('Cargo.toml')
    contents['package']['edition'] = '2018'
    save_toml('Cargo.toml', contents)

main()
