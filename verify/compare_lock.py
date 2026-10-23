# compare_lock.py <dnix.lock> <SHA256SUMS> [required-key-regex]: every library both list must hash
# the same, and every lock entry matching the regex must have been built.
import json, re, sys
lock = json.load(open(sys.argv[1]))["files"]
required = re.compile(sys.argv[3]) if len(sys.argv) > 3 else None
sums = {}
for line in open(sys.argv[2]):
    digest, path = line.split(maxsplit=1)
    sums[path.strip().removeprefix("./")] = digest
bad = compared = 0
for key, want in sorted(lock.items()):
    if key not in sums:
        needed = bool(required and required.search(key))
        bad += needed
        print(f"{'MISSING' if needed else '   not built here'}  {key}")
        continue
    compared += 1
    same = sums[key] == want
    bad += not same
    print(f"{'   same' if same else 'DIFFERS'}  {key}  {sums[key][:16]}" + ("" if same else f"  lock {want[:16]}"))
print(f"{compared} compared, {bad} problems")
sys.exit(1 if bad or not compared else 0)
