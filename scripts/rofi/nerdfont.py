#!/usr/bin/python

#
# Rofi nerd font glyphs selector. Python prototype
# usage: rofinerdfont.py
#

import os
import re
from subprocess import Popen, PIPE

# path to search nerd font glyphs database
nfg_basepath = os.path.join("/", "usr", "lib", "nerd-fonts-complete")

# process glyphs file
# return pair 'glyph' <-> 'description'
def get_glyphs_from_file(filename):
    pairs = []
    with open(filename, 'r') as f:
        regex = re.compile("i='(?P<glyph>.{1})'\s+i_(?P<description>\w+)=\$i")
        for line in f:
            matched = regex.search(line)
            if not matched is None:
                pairs.append({
                    "glyph" : matched.group("glyph"),
                    "description" : matched.group("description").replace("_", " ")})
    return pairs

# get all files with glyphs
# parse files and glyphs from it
all_glyphs = []
for filename in os.listdir(nfg_basepath):
    if filename.startswith("i_") and filename.endswith(".sh") and filename != "i_all.sh":
        nfg_filename = os.path.join(nfg_basepath, filename)
        glyph_entitys = get_glyphs_from_file(nfg_filename)
        for glyph_entity in glyph_entitys:
            all_glyphs.append("{} {}".format(glyph_entity["glyph"], glyph_entity["description"]))

# start rofi
args = ["rofi", "-dmenu", "-i", "-multi-select", "-kb-custom-1", "Alt+c"]
rofi = Popen(args, stdin=PIPE, stdout=PIPE)
(stdout, stderr) = rofi.communicate(input="\n".join(all_glyphs).encode("utf-8"))

# process rofi return results
if rofi.returncode != 1:
    glyphs = ""
    for line in stdout.splitlines():
        glyphs += line.split()[0].decode("utf-8")
    args = ["xclip", "-i", "-selection", "clipboard"]
    xclip = Popen(args, stdin=PIPE)
    xclip.communicate(input=glyphs.encode('utf-8'))
