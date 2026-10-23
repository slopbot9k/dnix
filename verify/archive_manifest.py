# archive_manifest.py <archive>: one line per member, "<sha256>  <size>  <name>#<occurrence>",
# sorted, so two hosts' static libraries can be compared member by member.
import hashlib, sys
data = open(sys.argv[1], "rb").read()
assert data[:8] == b"!<arch>\n", "not an ar archive"
pos, longnames, seen, rows = 8, b"", {}, []
while pos + 60 <= len(data):
    header = data[pos:pos + 60]; pos += 60
    name = header[:16].decode("latin1").rstrip()
    size = int(header[48:58].decode().strip())
    body = data[pos:pos + size]; pos += size + (size & 1)
    if name.startswith("#1/"):                       # BSD long name
        n = int(name[3:]); name, body = body[:n].decode("latin1").rstrip("\0"), body[n:]
    elif name == "//":                               # GNU long-name table
        longnames = body; continue
    elif name.startswith("/") and name[1:].isdigit():  # GNU long name
        off = int(name[1:])  # entries end in "/\n" (GNU) or a NUL (MSVC)
        ends = [i for i in (longnames.find(b"/\n", off), longnames.find(b"\0", off), longnames.find(b"\n", off)) if i >= 0]
        name = longnames[off:min(ends) if ends else len(longnames)].decode("latin1")
    if name in ("/", "/SYM64/", "__.SYMDEF", "__.SYMDEF SORTED", "/<ECSYMBOLS>/"):
        name = "<symbol table " + name + ">"
    name = name.rstrip("/")
    seen[name] = seen.get(name, 0) + 1
    rows.append(f"{hashlib.sha256(body).hexdigest()}  {size:>9}  {name}#{seen[name]}")
print("\n".join(sorted(rows, key=lambda r: r.split("  ", 2)[2])))
