#!/usr/bin/env python
# -*- coding: utf-8 -*-

from lxml import etree

DEBUG = False

NM_GIR = '/usr/share/gir-1.0/NM-1.0.gir'

NSS = {
    'ns': 'http://www.gtk.org/introspection/core/1.0',
    'c': 'http://www.gtk.org/introspection/c/1.0',
    'glib': 'http://www.gtk.org/introspection/glib/1.0',
}

def main():
    parser = etree.XMLParser(remove_blank_text=True)

    tree = etree.parse(NM_GIR, parser)

    root = tree.getroot()

    convert_constructors(root)

    remove_doc_versions(root)

    rename_number_fields(root)

    remove_in6_addr(root)

    remove_stat(root)

    remove_output_strings(root)

    remove_odd_output_strings(root)

    remove_string_arrays(root)

    remove_unsupported_callbacks(root)

    remove_output_flags(root)

    remove_u8_pointer_functions(root)

    remove_array_properties(root)

    remove_slist(root)

    remove_uint_pointer_return(root)

    remove_checkpoint_create(root)

    remove_add_and_activate_connection2(root)

    remove_bool_option(root)

    remove_u8_optional_nullable(root)

    remove_ip_routing_rule_set(root)

    tree.write('NM-1.0.gir', encoding='utf-8', xml_declaration=True, pretty_print=True)

def convert_constructors(root):
    for el in root.xpath('//ns:function[@name="new"]', namespaces=NSS):
        el.tag = "{http://www.gtk.org/introspection/core/1.0}constructor"

def remove_doc_versions(root):
    remove_by_xpath(root, './/ns:doc-version')

def rename_number_fields(root):
    for type_el in root.xpath('//*[@name and contains("0123456789", substring(@name, 1, 1))]', namespaces=NSS):
        type_el.attrib['name'] = '_' + type_el.attrib['name']

def remove_in6_addr(root):
    remove_by_xpath(root, '//ns:function[@c:identifier="nm_utils_inet6_ntop"]')

def remove_stat(root):
    remove_by_xpath(root, '//ns:parameter[.//ns:type/@c:type="const stat*"]')

def remove_output_strings(root):
    remove_by_xpath(root, '//ns:method[.//ns:type/@c:type="char**"]')
    remove_by_xpath(root, '//ns:method[.//ns:type/@c:type="const char**"]')
    remove_by_xpath(root, '//ns:function[.//ns:type/@c:type="char**"]')
    remove_by_xpath(root, '//ns:function[.//ns:type/@c:type="const char**"]')

def remove_odd_output_strings(root):
    remove_by_xpath(root, '//ns:function[.//ns:type/@c:type="const char* const*"]')

def remove_string_arrays(root):
    remove_by_xpath(root, '//ns:method[.//ns:array/@c:type="char**"]')

def remove_unsupported_callbacks(root):
    remove_by_xpath(root, '//ns:method[.//ns:type/@c:type="NMSettingClearSecretsWithFlagsFn"]')

def remove_output_flags(root):
    remove_by_xpath(root, '//ns:method[.//ns:type/@c:type="NMSettingSecretFlags*"]')
    remove_by_xpath(root, '//ns:method[.//ns:type/@c:type="NMSetting8021xCKFormat*"]')

def remove_u8_pointer_functions(root):
    remove_by_xpath(root, '//ns:function[.//ns:type[@name="guint8" and @c:type="gconstpointer"]]')
    remove_by_xpath(root, '//ns:function[.//ns:type[@name="guint8" and @c:type="gpointer"]]')

def remove_array_properties(root):
    remove_by_xpath(root, '//ns:property[.//ns:array[@name="GLib.PtrArray"]/ns:type[@name="IPAddress"]]')
    remove_by_xpath(root, '//ns:property[.//ns:array[@name="GLib.PtrArray"]/ns:type[@name="IPRoute"]]')
    remove_by_xpath(root, '//ns:property[.//ns:array[@name="GLib.PtrArray"]/ns:type[@name="TCQdisc"]]')
    remove_by_xpath(root, '//ns:property[.//ns:array[@name="GLib.PtrArray"]/ns:type[@name="TCTfilter"]]')
    remove_by_xpath(root, '//ns:property[.//ns:array[@name="GLib.PtrArray"]/ns:type[@name="TeamLinkWatcher"]]')
    remove_by_xpath(root, '//ns:property[.//ns:array[@name="GLib.PtrArray"]/ns:type[@name="SriovVF"]]')
    remove_by_xpath(root, '//ns:property[.//ns:array[@name="GLib.PtrArray"]/ns:type[@name="BridgeVlan"]]')

def remove_slist(root):
    remove_by_xpath(root, '//ns:function[.//ns:type/@name="GLib.SList"]')
    remove_by_xpath(root, '//ns:method[.//ns:type/@name="GLib.SList"]')

def remove_uint_pointer_return(root):
    remove_by_xpath(root, '//ns:function[.//ns:return-value/ns:type[@c:type="const guint*"]]')
    remove_by_xpath(root, '//ns:method[.//ns:return-value/ns:type[@c:type="const guint*"]]')

def remove_checkpoint_create(root):
    remove_by_xpath(root, '//ns:method[@name="checkpoint_create"]')

def remove_add_and_activate_connection2(root):
    remove_by_xpath(root, '//ns:method[@name="add_and_activate_connection2"]')
    remove_by_xpath(root, '//ns:method[@name="add_and_activate_connection2_finish"]')

def remove_bool_option(root):
    remove_by_xpath(root, '//ns:method[.//ns:parameter[@allow-none="1" and @nullable="1"]/ns:type[@c:type="gboolean*"]]')

def remove_u8_optional_nullable(root):
    remove_by_xpath(root, '//ns:function[.//ns:parameter[@allow-none="1" and @nullable="1"]/ns:type[@c:type="guint8*"]]')

def remove_ip_routing_rule_set(root):
    remove_by_xpath(root, '//ns:method[@c:identifier="nm_ip_routing_rule_set_from"]')
    remove_by_xpath(root, '//ns:method[@c:identifier="nm_ip_routing_rule_set_to"]')

def remove_by_xpath(root, xpath):
    if DEBUG:
        print('#######################################################')
        print('###', xpath)

    for el in root.xpath(xpath, namespaces=NSS):
        if DEBUG:
            try:
                print(el.attrib['{http://www.gtk.org/introspection/c/1.0}identifier'])
            except:
                try:
                    print(el.attrib['name'])
                except:
                    print(el.attrib.keys())
        remove_element(el)

def remove_element(element):
    element.getparent().remove(element)

if __name__ == '__main__':
    main()
