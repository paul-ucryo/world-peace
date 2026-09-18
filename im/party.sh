#i did not review this code. its a sample that should be expanded on and is probably not well written (i like more functional style). Its a place to build from not code to run. it was written by ai. who knows what ai is assembling itself into with all this vibe coding.
"""
fed - federated domain registry via FUSE

/etc/fed is ground truth. creating a directory in the registry
bootstraps a domain with identity, version control, and a GW resolver.

GW is the routing context - like PATH but generalized.
defined as an env variable, inherited and overridable per process.
each entry is a typed resolver: local, peer, fed.

domain address is derived from its public key.
routing is global. inspectability requires the key.
global and private simultaneously.
"""

import os
import sys
import stat
import errno
import hashlib
import base64
import subprocess
from pathlib import Path
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from cryptography.hazmat.primitives.asymmetric.x25519 import X25519PrivateKey
from cryptography.hazmat.primitives.serialization import (
    Encoding, PublicFormat, PrivateFormat, NoEncryption
)

try:
    import fuse
    from fuse import Fuse, Stat, FuseError
    fuse.fuse_python_api = (0, 2)
except ImportError:
    print("pip install fuse-python cryptography")
    sys.exit(1)


FED_ROOT = Path("/etc/fed")
DEFAULT_DOMAIN = FED_ROOT / "default"


# --- domain addressing ---
# address is derived from public key
# globally routable, only inspectable with the key
# the address IS the identity

def derive_address(public_key_bytes: bytes) -> str:
    """
    Derive a stable domain address from the public key.
    Address is deterministic - same key always produces same address.
    Opaque to the network, inspectable at the endpoint.
    Format: fed.<b32-encoded-key-fingerprint>
    """
    fingerprint = hashlib.sha256(public_key_bytes).digest()[:10]
    encoded = base64.b32encode(fingerprint).decode().lower().rstrip("=")
    return f"fed.{encoded}"


# --- GW resolver ---
# orthogonal to ACS but depends on it for key material
# defined as env variable - inherited, overridable per process/session/domain
# each resolver type knows how to search its own context
# resolution order: first match wins, like PATH
# but resolver types can be broadcast (query all, surface what responds)

class Resolver:
    """Base resolver. Each entry in GW is a typed resolver."""

    def __init__(self, spec: str):
        # spec format: type:location
        # e.g. local:./domains, peer:node.example, fed:registry.fed
        parts = spec.split(":", 1)
        self.kind = parts[0]
        self.location = parts[1] if len(parts) > 1 else ""

    def resolve(self, address: str) -> dict | None:
        """
        Attempt to resolve an address in this context.
        Returns capability descriptor or None if not found.
        """
        if self.kind == "local":
            return self._resolve_local(address)
        elif self.kind == "peer":
            return self._resolve_peer(address)
        elif self.kind == "fed":
            return self._resolve_fed(address)
        return None

    def _resolve_local(self, address: str) -> dict | None:
        base = Path(self.location)
        # look for domain by address file
        for domain in base.iterdir():
            addr_file = domain / "gw" / "address"
            if addr_file.exists() and addr_file.read_text().strip() == address:
                return {"kind": "local", "path": str(domain), "address": address}
        return None

    def _resolve_peer(self, address: str) -> dict | None:
        # placeholder - would do encrypted DNS lookup against peer node
        # onion-routed: peer only knows next hop, not full path
        return None

    def _resolve_fed(self, address: str) -> dict | None:
        # placeholder - would query federated registry
        # same onion routing, same encrypted DNS
        return None

    def __repr__(self):
        return f"{self.kind}:{self.location}"


class GW:
    """
    Gateway - generalized search context.
    Reads from GW env variable, falls back to default resolvers.
    Ordered like PATH - first match wins.
    Broadcast mode queries all resolvers and surfaces all responses.
    """

    DEFAULT_RESOLVERS = [
        f"local:{FED_ROOT}/registry",
        "fed:registry.fed",
    ]

    def __init__(self):
        raw = os.environ.get("GW", "")
        specs = [s.strip() for s in raw.split(",") if s.strip()] if raw else self.DEFAULT_RESOLVERS
        self.resolvers = [Resolver(spec) for spec in specs]

    def resolve(self, address: str, broadcast: bool = False) -> list[dict]:
        """
        Resolve an address across the search context.
        broadcast=False: return first match (PATH semantics)
        broadcast=True: return all matches (query everything)
        """
        results = []
        for resolver in self.resolvers:
            result = resolver.resolve(address)
            if result:
                if not broadcast:
                    return [result]
                results.append(result)
        return results

    def env_string(self) -> str:
        """Serialize back to env variable format."""
        return ",".join(str(r) for r in self.resolvers)

    @classmethod
    def with_domain_prepended(cls, domain_address: str, domain_path: Path) -> "GW":
        """
        Return a new GW with the given domain prepended to the search context.
        Used to narrow context for a specific domain's shell environment.
        """
        gw = cls()
        domain_resolver = Resolver(f"local:{domain_path.parent}")
        gw.resolvers.insert(0, domain_resolver)
        return gw



# --- handbook ---
# .hb files are the intent layer
# attached to any object - domain, directory, file, action
# freeform but timestamped - the why not the what
# meeting notes, dreams, proprietary app context, fs action rationale
# no schema - just write. git versions it. the address system finds it.

import datetime

HB_FILENAME = ".hb"


def hb_path(target):
    """
    .hb for any target.
    directory: inside it as .hb
    file: sibling .hb in same directory
    """
    if target.is_dir():
        return target / HB_FILENAME
    return target.parent / HB_FILENAME


def hb_append(target, entry, author="self"):
    """
    Append a timestamped entry to the handbook for this target.
    Creates .hb if it doesn't exist. No schema enforced - freeform.
    """
    hb = hb_path(target)
    timestamp = datetime.datetime.now(datetime.timezone.utc).isoformat()
    block = f"\n---\n{timestamp} [{author}]\n{entry.strip()}\n"
    with hb.open("a") as f:
        f.write(block)


def hb_read(target):
    """Full handbook for a target. None if absent."""
    hb = hb_path(target)
    if hb.exists():
        return hb.read_text()
    return None


def bootstrap_hb(domain_path, domain_name):
    """
    Seed the .hb for a new domain.
    Structural entry only - user fills in real intent.
    """
    addr_file = domain_path / "gw" / "address"
    address = addr_file.read_text().strip() if addr_file.exists() else "pending"
    hb_append(
        domain_path,
        f"domain: {domain_name}\naddress: {address}\nintent: (what is this domain for)",
        author="fed"
    )

# --- future: hb-driven git commits ---
# FUSE can intercept every write operation in a domain.
# rather than committing on every write (noisy), a callback decides:
#   - time since last commit
#   - number of changes accumulated
#   - explicit flush signal
# when commit triggers, read the domain .hb for the most recent entry
# and use that as the commit message.
# this means:
#   - the journal IS the commit log
#   - intent written in .hb flows automatically into version history
#   - no separate "write a commit message" step
#   - dreams, meeting notes, rationale all become part of the git record
#
# sketch:
#   def on_write(path):
#       domain = find_domain(path)
#       domain.change_buffer.add(path)
#       if should_commit(domain):
#           hint = hb_latest_entry(domain.path)
#           git_commit(domain.path, message=hint or "fed: auto-commit")
#
#   def hb_latest_entry(domain_path):
#       content = hb_read(domain_path)
#       if not content:
#           return None
#       # last --- block is the most recent entry
#       blocks = content.strip().split("\n---\n")
#       return blocks[-1].strip() if blocks else None
#
# the commit policy itself could live in .hb or domain config,
# monadic fallback to default. each domain decides its own rhythm.

# --- monadic config resolution ---

def resolve(domain_path: Path, key: str):
    """
    Walk domain -> default for any config key.
    Domain overrides default, default fills anything missing.
    """
    for base in [domain_path, DEFAULT_DOMAIN]:
        candidate = base / key
        if candidate.exists():
            return candidate.read_text().strip()
    return None


# --- bootstrap ---

def bootstrap_domain(domain_path: Path):
    """
    Called when a new domain directory is created.
    Creates identity keys and initializes git.
    Inherits anything not present from default.
    """
    domain_path.mkdir(parents=True, exist_ok=True)

    # acs/identity_keys
    acs = domain_path / "acs" / "identity_keys"
    acs.mkdir(parents=True, exist_ok=True)

    private_key_path = acs / "identity.priv"
    public_key_path = acs / "identity.pub"

    if not private_key_path.exists():
        key = Ed25519PrivateKey.generate()

        private_key_path.write_bytes(
            key.private_bytes(Encoding.PEM, PrivateFormat.PKCS8, NoEncryption())
        )
        private_key_path.chmod(0o600)

        pub_bytes = key.public_key().public_bytes(Encoding.PEM, PublicFormat.SubjectPublicKeyInfo)
        public_key_path.write_bytes(pub_bytes)

        # derive domain address from public key
        # address is globally routable, inspectable only with this key
        address = derive_address(pub_bytes)
        gw_dir = domain_path / "gw"
        gw_dir.mkdir(parents=True, exist_ok=True)
        (gw_dir / "address").write_text(address)

        # X25519 key for onion-style encryption layer (separate from signing key)
        enc_key = X25519PrivateKey.generate()
        (acs / "enc.priv").write_bytes(
            enc_key.private_bytes(Encoding.PEM, PrivateFormat.PKCS8, NoEncryption())
        )
        (acs / "enc.priv").chmod(0o600)
        (acs / "enc.pub").write_bytes(
            enc_key.public_key().public_bytes(Encoding.PEM, PublicFormat.SubjectPublicKeyInfo)
        )

        print(f"  address: {address}")

    # vcs - git
    git_dir = domain_path / ".git"
    if not git_dir.exists():
        subprocess.run(["git", "init", str(domain_path)], check=True, capture_output=True)
        subprocess.run(
            ["git", "commit", "--allow-empty", "-m", "init: domain bootstrap"],
            cwd=str(domain_path),
            check=True,
            capture_output=True,
            env={**os.environ, "GIT_AUTHOR_NAME": "fed", "GIT_AUTHOR_EMAIL": "fed@local",
                 "GIT_COMMITTER_NAME": "fed", "GIT_COMMITTER_EMAIL": "fed@local"}
        )

    # handbook - seed intent layer for this domain
    bootstrap_hb(domain_path, domain_path.name)

    print(f"bootstrapped: {domain_path.name}")


def ensure_default():
    """
    /etc/fed/default must exist before anything else.
    Minimal sensible defaults.
    """
    DEFAULT_DOMAIN.mkdir(parents=True, exist_ok=True)

    defaults = {
        "acs/policy": "owner-only",
        "vcs/backend": "git",
        "mount/mode": "private",
        "gw/resolvers": ",".join(GW.DEFAULT_RESOLVERS),
        "gw/mode": "first-match",  # or broadcast
    }

    # seed default handbook if absent
    default_hb = DEFAULT_DOMAIN / ".hb"
    if not default_hb.exists():
        hb_append(
            DEFAULT_DOMAIN,
            "domain: default\nintent: ground truth - monadic fallback for all domains\n"
            "edit this to change what every domain inherits",
            author="fed"
        )

    for key, value in defaults.items():
        path = DEFAULT_DOMAIN / key
        path.parent.mkdir(parents=True, exist_ok=True)
        if not path.exists():
            path.write_text(value)


# --- FUSE filesystem ---

class FedFS(Fuse):
    """
    Watches the registry directory.
    mkdir triggers domain bootstrap.
    dotfile symlink points to FUSE device (domain mount point).
    """

    def __init__(self, registry_path: Path, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.registry = registry_path
        self.registry.mkdir(parents=True, exist_ok=True)

    def _domain_path(self, name: str) -> Path:
        return self.registry / name

    def _hidden_path(self, name: str) -> Path:
        return self.registry / f".{name}"

    def getattr(self, path):
        real = self.registry / path.lstrip("/")
        if not real.exists():
            return -errno.ENOENT
        st = Stat()
        s = real.stat()
        st.st_mode = s.st_mode
        st.st_nlink = s.st_nlink
        st.st_size = s.st_size
        st.st_atime = s.st_atime
        st.st_mtime = s.st_mtime
        st.st_ctime = s.st_ctime
        return st

    def readdir(self, path, offset):
        real = self.registry / path.lstrip("/")
        yield fuse.Direntry(".")
        yield fuse.Direntry("..")
        for entry in real.iterdir():
            yield fuse.Direntry(entry.name)

    def mkdir(self, path, mode):
        name = Path(path).name
        domain_path = self._domain_path(name)
        hidden_path = self._hidden_path(name)

        # bootstrap the domain
        bootstrap_domain(domain_path)

        # symlink .{name} -> domain path (inspection point)
        if not hidden_path.exists():
            hidden_path.symlink_to(domain_path)

        # write GW env for this domain's shell context
        # inherits global GW, prepends domain as first resolver
        gw = GW.with_domain_prepended(domain_path.name, domain_path)
        gw_env_path = domain_path / "gw" / "env"
        gw_env_path.parent.mkdir(parents=True, exist_ok=True)
        gw_env_path.write_text(f"GW={gw.env_string()}\n")

        return 0

    def readlink(self, path):
        real = self.registry / path.lstrip("/")
        if real.is_symlink():
            return str(real.resolve())
        return -errno.EINVAL


# --- entry point ---

def main():
    ensure_default()

    registry = FED_ROOT / "registry"

    fs = FedFS(registry_path=registry)
    fs.parse(errex=1)
    fs.main()


if __name__ == "__main__":
    main()
