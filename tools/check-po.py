#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Rafael Ruscher <rruscher@gmail.com>
# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
#
# Validates every locale/*.po beyond `msgfmt --check`:
#   - the %1..%9 / %n placeholders in each translation match the source;
#   - plural entries provide the number of forms declared in Plural-Forms;
#   - no fuzzy or untranslated entries remain (reported, non-fatal unless --strict).
# Usage: tools/check-po.py [--strict]
import glob, os, re, sys, subprocess

strict = "--strict" in sys.argv
placeholder = re.compile(r"%\d+|%n")
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
errors = 0
warnings = 0

def blocks(path):
    block = []
    for line in open(path, encoding="utf-8"):
        if line.strip() == "":
            if block:
                yield block
                block = []
        else:
            block.append(line.rstrip("\n"))
    if block:
        yield block

def joined(block, prefix):
    out, capturing = "", False
    for line in block:
        if line.startswith(prefix):
            capturing = True
            rest = line[len(prefix):].strip()
            out += eval(rest) if rest.startswith('"') else ""
        elif capturing and line.startswith('"'):
            out += eval(line.strip())
        elif capturing and not line.startswith('"'):
            capturing = False
    return out

def msgstr_indexed(block, idx):
    prefix = f"msgstr[{idx}]"
    return joined(block, prefix)

for po in sorted(glob.glob(os.path.join(root, "locale", "*.po"))):
    lang = os.path.basename(po)[:-3]
    nplurals = None
    for b in blocks(po):
        header = "\n".join(b)
        if 'msgid ""' in b[0:2] and "Plural-Forms" in header:
            m = re.search(r"nplurals=(\d+)", header)
            if m:
                nplurals = int(m.group(1))
    for b in blocks(po):
        text = "\n".join(b)
        is_fuzzy = any(l.startswith("#,") and "fuzzy" in l for l in b)
        msgid = joined(b, "msgid ")
        if not msgid:
            continue  # header
        msgid_plural = joined(b, "msgid_plural ")
        if msgid_plural:
            src = set(placeholder.findall(msgid)) | set(placeholder.findall(msgid_plural))
            forms = nplurals or 2
            for i in range(forms):
                t = msgstr_indexed(b, i)
                if t == "":
                    warnings += 1
                    continue
                if set(placeholder.findall(t)) - src:
                    if is_fuzzy:
                        warnings += 1
                    else:
                        print(f"{lang}: extra placeholder in plural form {i}: {msgid!r} -> {t!r}")
                        errors += 1
        else:
            t = joined(b, "msgstr ")
            if t == "":
                warnings += 1
                continue
            src = set(placeholder.findall(msgid))
            got = set(placeholder.findall(t))
            if src != got:
                if is_fuzzy:
                    warnings += 1  # not compiled into the .mo; translation memory only
                else:
                    print(f"{lang}: placeholder mismatch: {msgid!r} {sorted(src)} -> {t!r} {sorted(got)}")
                    errors += 1
            elif is_fuzzy:
                warnings += 1

print(f"placeholder/plural errors: {errors}; untranslated+fuzzy entries: {warnings}")
if errors or (strict and warnings):
    sys.exit(1)
