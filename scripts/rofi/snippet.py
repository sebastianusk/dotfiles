#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Copyright © 2017 Samuel Walladge
# fuzzy search for text snippets to copy to clipboard
# depends on PyYaml, rofi, xclip, xdotool, and a yaml file containing key:snippet pairs

import yaml
import sys
import subprocess

from subprocess import Popen, PIPE

COPY = 'copy'
TYPE = 'type'

if len(sys.argv) < 3:
    print('Usage: clip-snippet.py copy|type YAML_DB_FILENAME')
    sys.exit()

mode = sys.argv[1]
db_filename = sys.argv[2]

if mode not in (COPY, TYPE):
    print('Invalid mode! Must be either copy or type.')
    sys.exit(-1)


try:
    # { 'name': 'snippet' }
    db = yaml.load(open(db_filename))
except Exception as e:
    print('Failed to load database file ({!r})!'.format(db_filename))
    print('Ensure that it exists and is a valid yaml file.\n')
    print(e)
    sys.exit(-1)


keys = '\n'.join(db.keys())
result = subprocess.run(['rofi', '-dmenu', '-no-custom', '-p', 'snippet:', '-matching', 'fuzzy'],
        input=keys, stdout=subprocess.PIPE, encoding='utf-8')
if result.returncode != 0:
    sys.exit(-1)

key = result.stdout.strip()
snippet = db.get(key, None)
if snippet is None:
    sys.exit(-1)

# copy to primary and clipboard selection
if mode == COPY:
    args = ["xclip", "-i", "-selection", "clipboard"]
    xclip = Popen(args, stdin=PIPE)
    xclip.communicate(input=snippet.encode('utf-8'))
elif mode == TYPE:
    subprocess.run(['xdotool', 'type', '--', snippet], encoding='utf-8')
