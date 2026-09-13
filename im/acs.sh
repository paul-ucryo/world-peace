#!/usr/bin/env bash
#Happy birthday! This file creates or reconnects to the acs system.
#I don't think the vcs is well described, the idea of using cow send blocks as a diff engine (pijul style vcs over zfs/btrfs where the kernel ns tree (fs) is a block pager with a tcp socket map.

fs="zfs"
declare -A ns
ns[acs.fs]="/etc/acs"
ns[acs.$USER.fs]="/home/${USER}/.config/acs"
openssl genpkey -algorithm ed25519 -out .$$.ed25519.pem
openssl pkey -in .$$.ed25519.pem -pubout -out .$$.ed25519.pub
ch=$(openssl pkey -in .$$.ed25519.pub -pubin -outform DER | sha256sum | cut -c1-16)

ns[im]
ns[gw._.fs]="/fed"
ns[gw._]="/fed/$ch"
dom="${ns[gw._.fs]}"
ns[gw.$ch.fs]="/home/$USER/.local/share/gw"
d="${ns[acs.$USER.fs]}"
gw="${ns[gw.$ch.fs]}"
size="10G"

sudo mkdir -p $dom
mkdir -p $d/.$ch
mkdir -p $gw
#mkdir -p "/home/$USER/.local/share/share/"
mv ".$$.ed25519.pem" "$d/.$ch/pem"
mv ".$$.ed25519.pub" "$d/.$ch/pub"
ln -s "$d/.$ch" "$d/$$"

truncate -s "$size" "$gw/.$ch"
sudo cryptsetup luksFormat --type luks2 --batch-mode \
    --key-file "$d/.$ch/pem" "$gw/.$ch"
sudo cryptsetup open --key-file "$d/.$ch/pem" "$gw/.$ch" "$ch"
#sudo mkfs."$fs" "/dev/mapper/$ch"
#sudo mount "/dev/mapper/$ch" "$dom"
sudo zpool create -m "$dom/$ch" "gw.$ch" "/dev/mapper/$ch"
sudo chown "$USER" "$dom/$ch"

sudo zfs snapshot "gw.$ch@$$"
h=$(sudo zfs send "gw.$ch@$$" | sha256sum | cut -c1-16)
sudo zfs rename "gw.$ch@$$" "gw.$ch@$h"

sudo fatrace -c -f CW+ "$dom/$ch" | while read -r comm pid ev path; do
    (( $(zfs get -Hp -o value written "gw.$ch") > limit )) && frame
done &
#fr=$1

#this should be implemented something like registering with a scheduler.


#trap 'rm -rf "$(readlink -f "$d/$$")" "$d/$$"' EXIT

dirs=("every.{sec}" "written.{size}" "on.close")
for i in "${dirs[@]}"; do
    mkdir -p "$dom/$i
done

"""
Lazy directory listing service.

GET /ls?path=/var/log&cursor=<name>&limit=200&attrs=1

Response (compact JSON):
{
  "d":    "/var/log",                 # directory path
  "g":    "1a2b3c",                    # generation (changes when dir changes)
  "n":    [["syslog","f",48211,1726012300], ["nginx","d"]],
  "next": "syslog"                     # cursor for the next page, or null
}

Entry tuple: [name, kind]  or  [name, kind, size, mtime, mode]  with attrs=1
kind: "f" file, "d" dir, "l" symlink, "o" other
"""
import json
import os
import stat
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

ROOT = os.path.realpath(sys.argv[1] if len(sys.argv) > 1 else ".")
DEFAULT_LIMIT = 200
MAX_LIMIT = 2000


def resolve(rel_path: str) -> str:
    """Map a request path onto the served root, refusing escapes."""
    full = os.path.realpath(os.path.join(ROOT, rel_path.lstrip("/")))
    if full != ROOT and not full.startswith(ROOT + os.sep):
        raise PermissionError(rel_path)
    return full


def kind_of(entry: os.DirEntry) -> str:
    # follow_symlinks=False so d_type is used and no extra stat happens
    if entry.is_symlink():
        return "l"
    if entry.is_dir(follow_symlinks=False):
        return "d"
    if entry.is_file(follow_symlinks=False):
        return "f"
    return "o"


def generation(full: str) -> str:
    st = os.stat(full)
    return format(st.st_mtime_ns ^ st.st_ino, "x")


def list_dir(rel_path: str, cursor: str | None, limit: int, attrs: bool) -> dict:
    full = resolve(rel_path)
    limit = max(1, min(limit, MAX_LIMIT))

    # Sort by name so the cursor is position-independent: a deleted entry
    # doesn't shift the rest, a new one just appears (or not) in order.
    with os.scandir(full) as it:
        entries = sorted(it, key=lambda e: e.name)

    if cursor is not None:
        entries = [e for e in entries if e.name > cursor]

    page = entries[:limit]
    out = []
    for e in page:
        row = [e.name, kind_of(e)]
        if attrs:
            try:
                st = e.stat(follow_symlinks=False)
                row += [st.st_size, int(st.st_mtime), stat.S_IMODE(st.st_mode)]
            except OSError:
                row += [None, None, None]
        out.append(row)

    return {
        "d": "/" + os.path.relpath(full, ROOT).replace(os.sep, "/").strip("."),
        "g": generation(full),
        "n": out,
        "next": page[-1].name if len(entries) > limit else None,
    }


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        url = urlparse(self.path)
        if url.path != "/ls":
            return self._send(404, {"error": "not found"})
        q = parse_qs(url.query)
        try:
            body = list_dir(
                q.get("path", ["/"])[0],
                q.get("cursor", [None])[0],
                int(q.get("limit", [DEFAULT_LIMIT])[0]),
                q.get("attrs", ["0"])[0] == "1",
            )
            self._send(200, body)
        except FileNotFoundError:
            self._send(404, {"error": "no such directory"})
        except NotADirectoryError:
            self._send(400, {"error": "not a directory"})
        except PermissionError:
            self._send(403, {"error": "forbidden"})

    def _send(self, code: int, obj: dict):
        data = json.dumps(obj, separators=(",", ":")).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *_):
        pass


if __name__ == "__main__":
    print(f"serving {ROOT} on http://127.0.0.1:8080/ls")
    ThreadingHTTPServer(("127.0.0.1", 8080), Handler).serve_forever()
