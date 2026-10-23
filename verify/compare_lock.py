# compare_lock.py <dnix.lock> <SHA256SUMS>: every library both list must hash the same.
import json, sys
lock = json.load(open(sys.argv[1]))["files"]
sums = {}
for line in open(sys.argv[2]):
    digest, path = line.split(maxsplit=1)
    sums[path.strip().removeprefix("./")] = digest
bad = compared = 0
for key, want in sorted(lock.items()):
    if key not in sums:
        print(f"   not built here  {key}")
        continue
    compared += 1
    same = sums[key] == want
    bad += not same
    print(f"{'   same' if same else 'DIFFERS'}  {key}  {sums[key][:16]}" + ("" if same else f"  lock {want[:16]}"))
print(f"{compared} compared, {bad} differ")
sys.exit(1 if bad or not compared else 0)
