"""trace_summary.py <out-link>...: per build tool, how many processes loaded
the tracing qsort and how many qsort calls had ties between different
elements, from each target's debug/qsort-trace.log."""
import collections
import pathlib
import sys

rows = []
for link in sys.argv[1:]:
    target = pathlib.Path(link).name.removeprefix("trace-")
    log = pathlib.Path(link) / "debug" / "qsort-trace.log"
    loaded = collections.defaultdict(set)
    calls = collections.Counter()
    ties = collections.Counter()
    if log.exists():
        for line in log.read_text(errors="replace").splitlines():
            parts = line.split()
            if len(parts) < 3:
                continue
            tool, pid = parts[0], parts[1]
            if parts[2] == "loaded":
                loaded[tool].add(pid)
            else:
                calls[tool] += 1
                ties[tool] += int(parts[-1].split("=")[1])
    for tool in sorted(set(loaded) | set(calls)):
        rows.append((target, tool, len(loaded[tool]), calls[tool], ties[tool]))

print(f"{'target':<28} {'tool':<24} {'processes':>9} {'calls with ties':>15} {'ties':>9}")
for target, tool, procs, c, t in rows:
    print(f"{target:<28} {tool:<24} {procs:>9} {c:>15} {t:>9}")
