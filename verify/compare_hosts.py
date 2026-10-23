# compare_hosts.py <dir>: <dir>/sums-<package>-<host>/SHA256SUMS from each build host; every file that
# more than one host built must hash the same everywhere. Prints a table and annotations.
import collections, pathlib, re, sys
by_package = collections.defaultdict(dict)
for sums in sorted(pathlib.Path(sys.argv[1]).glob("sums-*/SHA256SUMS")):
    package, host = re.fullmatch(r"sums-(.+)--(.+)", sums.parent.name).groups()
    files = {}
    for line in sums.read_text().splitlines():
        digest, path = line.split(maxsplit=1)
        files[path.strip().removeprefix("./")] = digest
    by_package[package][host] = files
bad = 0
for package, hosts in sorted(by_package.items()):
    files = sorted(set().union(*hosts.values()))
    differing = []
    for path in files:
        seen = {host: sums[path] for host, sums in hosts.items() if path in sums}
        if len(set(seen.values())) > 1:
            differing.append((path, seen))
    shared = sum(1 for path in files if sum(path in s for s in hosts.values()) > 1)
    print(f"{package}: {len(files)} files from {', '.join(sorted(hosts))}; {shared} built on more than one host; {len(differing)} differ")
    for path, seen in differing:
        print("   DIFFERS", path, " ".join(f"{h}={d[:12]}" for h, d in sorted(seen.items())))
    if differing:
        bad += 1
        print(f"::error title={package} differs between hosts::" + "; ".join(p for p, _ in differing))
    else:
        print(f"::notice title={package} identical on every host::{shared} files built on more than one host are byte-identical across {', '.join(sorted(hosts))}")
sys.exit(1 if bad else 0)
