#!/usr/bin/env python
# -*- coding: utf-8 -*-

import itertools
import json
import qtoml

from collections import OrderedDict as odict

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

    generate_cargo_toml(namespace)

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

def generate_cargo_toml(namespace):
    versions = set()

    for key, value in namespace.items():
        if isinstance(value, list):
            collect_versions(value, versions)
    
    versions = list(versions)
    versions.sort(key=version_key)
    for version in versions:
        print(version)

def version_key(version):
    splitted = version.split('.')
    return int(splitted[1])

def collect_versions(value, versions):
    if isinstance(value, dict):
        if '@version' in value:
            version = value['@version']
            versions.add(version)

        for key, inner in value.items():
            collect_versions(inner, versions)

    if isinstance(value, list):
        for inner in value:
            collect_versions(inner, versions)

def read_json(path):
    f = open(path, 'r')
    data = json.load(f)
    f.close()
    return data

def save_toml(path, contents):
    toml = qtoml.dumps(contents)
    f = open(path, 'w')
    f.write(toml)
    f.close()

generate()
