#!/usr/bin/env python
# -*- coding: utf-8 -*-

import itertools
import json


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


def add_names(namespaces, namespace_name, names):
    ### print('######################################')
    ### print('#', namespace_name)
    namespace = namespaces[namespace_name]
    for entity in namespace:
        if type(entity) == str:
            continue

        name = entity['@name']

        names.append(name)
        ### print(name)


def extract_objects(file_name):
    nm_json = read_json(file_name)

    strip_namespaces(nm_json)

    namespace = nm_json['repository']['namespace']

    names = []

    add_names(namespace, 'bitfield', names)
    add_names(namespace, 'enumeration', names)
    ### add_names(namespace, 'constant', names)
    add_names(namespace, 'class', names)
    ### add_names(namespace, 'record', names)
    add_names(namespace, 'interface', names)
    add_names(namespace, 'callback', names)
    ### add_names(namespace, 'function', names)

    names.sort()

    return names


MANUAL = '''
manual = [
    "GObject.Object",
    "GLib.ByteArray",
    "GLib.Bytes",
    "GLib.FileTest",
    "GLib.Error",
    "GLib.KeyFile",
    "GLib.ObjectClass",
    "GLib.PtrArray",
    "GLib.Variant",
    "GLib.VariantType",
    "Gio.AsyncReadyCallback",
    "Gio.Cancellable",
    "Gio.DBusConnection",
    "Gio.DBusInterfaceInfo",
    "Gio.DBusMethodInvocation",
    "Gio.DBusObjectManagerClientFlags",
    "Gio.DBusProxy",
    "Gio.InputStream",
    "Gio.OutputStream",
]
'''


def generate_nm_toml():
    names = extract_objects('/build/json/NM-1.0.json')

    names = ['    "NM.' + name + '",\n' for name in names]

    toml = '''[options]
girs_dir = "gir-files"
library = "NM"
version = "1.0"
#min_cfg_version = "1.2"
target_path = "."
work_mode = "normal"
single_version_file = true

generate = [
    "NM.*",
{}]

{}
'''.format(''.join(names), MANUAL)

    save_file('/build/libnm-rs/Gir_NM.toml', toml)


def generate_mm_toml():
    names = extract_objects('/build/json/ModemManager-1.0.json')

    names = ['    "ModemManager.' + name + '",\n' for name in names]

    toml = '''[options]
girs_dir = "gir-files"
library = "ModemManager"
version = "1.0"
#min_cfg_version = "1.2"
target_path = "."
work_mode = "normal"
single_version_file = true

generate = [
    "ModemManager.*",
{}]

{}
'''.format(''.join(names), MANUAL)

    save_file('/build/libmm-rs/Gir_ModemManager.toml', toml)


def read_json(path):
    f = open(path, 'r')
    data = json.load(f)
    f.close()
    return data


def save_file(path, contents):
    f = open(path, 'w')
    f.write(contents)
    f.close()


generate_nm_toml()

generate_mm_toml()

