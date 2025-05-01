#!/usr/bin/env python3
import xml.etree.ElementTree as ET

tree = ET.parse("coverage.xml")
root = tree.getroot()

lines = ["| File | Stmts | Miss | Cover |", "|------|-------|------|--------|"]

for cls in root.findall(".//class"):
    fname = cls.attrib["filename"]
    lines_total = int(cls.attrib["lines-valid"])
    lines_missed = int(cls.attrib["lines-missed"])
    coverage = float(cls.attrib["line-rate"]) * 100
    lines.append(f"| `{fname}` | {lines_total} | {lines_missed} | {coverage:.1f}% |")

overall = float(root.attrib["line-rate"]) * 100
print(f"![Coverage](https://ckuhtz.github.io/fissure/coverage.svg)\n")
print(f"### 🧪 Test Coverage Report\n> Total: **{overall:.1f}%**\n")
print("\n".join(lines))
