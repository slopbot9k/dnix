# extract_symbols.py <package checkout> <bindings file relative to it>: print the native symbols its Dart code binds, one per line.
import re, sys, pathlib
src = (pathlib.Path(sys.argv[1]) / sys.argv[2]).read_text()
names = set()
for m in re.finditer(r"@(?:ffi\.)?Native<(?:[^()]|\([^()]*\))*?>\s*\(([^)]*)\)\s*(?:external\s+)?[\w<>.,\s]*?\s+(\w+)\s*\(", src, re.S):
    sm = re.search(r"symbol:\s*'([^']+)'", m.group(1))
    names.add(sm.group(1) if sm else m.group(2))
declared = len(re.findall(r"@(?:ffi\.)?Native<", src))
if declared != len(names):
    sys.exit(f"found {declared} @Native declarations but parsed {len(names)} symbols")
print("\n".join(sorted(names)))
