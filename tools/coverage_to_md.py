#!/usr/bin/env python3
import xml.etree.ElementTree as ET

tree = ET.parse("coverage.xml")
root = tree.getroot()

lines = ["| File | Stmts | Miss | Cover |", "|------|-------|------|--------|"]

for file in root.findall(".//packages/package/classes/class"):
    filename = file.attrib.get("filename", "???")
    lines_elem = file.find("lines")
    total = 0
    missed = 0
    for line in lines_elem.findall("line"):
        total += 1
        if int(line.attrib["hits"]) == 0:
            missed += 1
    covered = ((total - missed) / total * 100) if total else 0
    lines.append(f"| `{filename}` | {total} | {missed} | {covered:.1f}% |")

overall = float(root.attrib.get("line-rate", "0")) * 100
print("![Coverage](https://ckuhtz.github.io/fissure/coverage.svg)\n")
print(f"### 🧪 Test Coverage Report\n> Total: **{overall:.1f}%**\n")
print("\n".join(lines))