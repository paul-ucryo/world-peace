# The Filesystem as Interpreter

## The Core Idea

A FUSE filesystem where **the filename is the function call** and **the file contents are the arguments**. Writing to the OS is executing a program. The filesystem is not storage — it is a runtime.

```
write("_cipher.generate", "{user: alice, project: door}")
read("_cipher.generate") → "m4x8n2v6j5"
```

No API. No SDK. No library. If you can open and write a file, you can program the system.

---

## The `_` Protocol

Any write to a file beginning with `_` is a function call. FUSE intercepts it, dispatches to the registered generator, and returns the result as both the file content and a new filename in the flat store.

```
_ ← sentinel: "I need a new identity"
_cipher.generate ← call this generator
_hash.geometry ← call this one
_seq.catalog.fasteners ← call this one
```

The generator doesn't need to know about the application. The application doesn't need to know about the generator. FUSE is the contract between them.

---

## The Flat Store and Catalog

Every generated file lands in a flat store with an opaque, generated name:

```
/store/
  a7f2k9p3q1/
  m4x8n2v6j5/
  w9q1r7t4k2/
```

The catalog is a symlink layer over the flat store, organized by human-readable descriptions:

```
/catalog/
  structural/
    main-bracket → ../../store/m4x8n2v6j5
  fasteners/
    m6-hex-bolt → ../../store/w9q1r7t4k2
  assemblies/
    door-assembly → ../../store/a7f2k9p3q1
```

Users navigate by description. Applications open opaque IDs. They are the same file.

---

## Generators

A generator is any function registered with FUSE that produces an identifier. The level of complexity is a policy choice, not a constraint:

| Generator | Properties |
|---|---|
| `_cipher.user.project` | Unique, distributed, encodes metadata, access-controlled |
| `_hash.geometry` | Same shape = same ID, content-addressed |
| `_seq.catalog` | Simple counter, human-readable, local scope |
| `_uuid` | Unique, no coordination, no encoded meaning |

**Generators are composable.** Pipe the output of one into another using path syntax:

```
_cipher.user|hash.geometry.project
```

Geometry hash feeds into the cipher. The result inherits properties of both.

---

## Cascades

When a file is written, FUSE can trigger cascades across dependent files. The filesystem becomes a **live dataflow graph**:

```
bolt spec updated
  → FUSE sees write to w9q1r7t4k2
  → cascade checks: who references this file?
  → door-assembly references it
  → door-assembly flagged: dependency changed
  → engineer sees "assembly needs review"
```

No manual dependency tracking. No build system bolted on top. The runtime knows because the generators know.

Updating one generator cascades across all files derived from it. The filesystem reasons about itself.

---

## Configuration is Execution

The `/fuse/` directory is both the interface definition and the config structure:

```
/fuse/
  _cipher.generate
  _hash.geometry
  _cascade.on_write
  _symlink.catalog
```

Configuring the system means writing argument payloads to these files. There is no separate config format. The call structure *is* the config structure.

**Introspection is free** — `ls /fuse/` is your API reference.  
**Logging is free** — every write is already an OS event.  
**Composition is free** — pipe the output of one call as the input to the next.

---

## The SolidWorks Workflow

An engineer opens SolidWorks, navigates `/catalog/structural/`, clicks `main-bracket`. SolidWorks opens `m4x8n2v6j5`. The engineer never sees the ID.

The engineer hits save:

```
SolidWorks writes to _
  → FUSE intercepts
  → generator runs (user shard + project + timestamp)
  → returns m4x8n2v6j5
  → file lands in /store/m4x8n2v6j5
  → catalog symlink updates
  → part number field auto-populates from description attributes
  → any assembly referencing this part is notified
```

The engineer sees: file saved.

**Two engineers, same part, no conflict:**

```
Alice saves → m4x8n2v6j5
Bob saves   → r3p9k1n7x4
```

Both exist. The catalog shows both. Reconciliation is a deliberate reasoning step, not a filesystem emergency.

---

## Security Stack

Security is not a policy bolted on. It is structural, enforced at every layer by the layer beneath it.

### LUKS — Block Boundary

LUKS is the outermost boundary. The volume either mounts or it doesn't. Access control is defined by which keys can unlock which volumes — before the filesystem sees any data. Different volumes for different access tiers. Cryptographically enforced at the block level.

```
LUKS volume A ← engineering team keys
LUKS volume B ← management keys
LUKS volume C ← public read keys
```

### ZFS Encryption — Data Boundary

ZFS encryption operates per-dataset, finer grained than LUKS. Different parts of the same pool can be encrypted to different keys — different projects, users, or access tiers coexist in the same store but are cryptographically isolated from each other.

ZFS also provides signatures and capability-style access within the store. A file can be readable to one key, writable to another, invisible to a third — all within the same flat store, without a separate access control system.

```
/store/
  engineering/   ← encrypted to engineering keypair
  management/    ← encrypted to management keypair
  public/        ← unencrypted or broadly readable
```

### ZFS Snapshots — Delta Algebra

ZFS snapshots are cheap, atomic, and composable. Treated not as backups but as a **pijul-style patch algebra** — a mathematically sound history where:

- Patches commute — order of independent changes doesn't matter
- Conflicts are explicit — not implicit in a merge
- State is reasoned over, not just replayed
- Any snapshot can be diffed, applied, or rolled back as a first-class operation

The history of the store is not a log. It is an algebra over state changes. You can compose, invert, and reason over patches the same way you compose generators.

```
snapshot_t0 + patch_A + patch_B = snapshot_t2
snapshot_t2 - patch_B = snapshot_t1   ← revert B, keep A
patch_A ∘ patch_B = patch_AB          ← compose into single delta
```

### The Full Security Stack

```
LUKS            ← block boundary, volume-level ACS
ZFS encryption  ← dataset boundary, identity/capability layer
ZFS snapshots   ← delta algebra, history as math not log
FUSE            ← filesystem interpreter, generator/cascade layer
```

Each layer is cryptographically enforced. Each defines a different boundary. The ACS is not configured — it is the structure.

---

## Per-Directory Kernel Call Handlers

Every directory can define its own behavior for reads and writes via two special files:

```
_read  ← defines what happens on every read call in this directory
_save  ← defines what happens on every write call in this directory
```

FUSE intercepts kernel calls, checks for `_read` and `_save` in the directory, and executes them. The directory is not a location — it is a **behavior definition**.

```
/catalog/
  local-parts/
    _read  ← read from /store
    _save  ← write to /store, run generators

  remote-parts/
    _read  ← forward to tcp://192.168.1.5, return response
    _save  ← forward to tcp://192.168.1.5, return response

  s3-archive/
    _read  ← forward to s3://bucket
    _save  ← forward to s3://bucket, also snapshot locally

  replicated/
    _read  ← read local
    _save  ← write local AND forward to tcp://peer1, tcp://peer2
```

Same POSIX interface everywhere. The behavior is entirely in `_read` and `_save`. Because those files are themselves writable and versioned by ZFS snapshots, directory behavior is live and auditable — change `_save`, FUSE picks it up, the directory behaves differently.

---

## Socket Protocol

A socket endpoint is just a file. Its behavior is defined by `_read` and `_save` in its directory. There is no special transport layer — the `_` protocol runs identically over local disk or a TCP connection.

```
/catalog/remote-parts/
  _read  ← forward read calls to tcp://192.168.1.5, return response
  _save  ← forward write calls to tcp://192.168.1.5, return response
  _auth  ← key to present when connecting
  k3p7n2x9  ← name in the catalog, behavior inherited from _read/_save
```

A remote node running the same filesystem interpreter is indistinguishable from a local directory. Symlinks can point anywhere:

```
/catalog/
  structural/
    main-bracket → ../../store/m4x8n2v6j5         ← local
    remote-part  → tcp://192.168.1.5/store/k3p7    ← remote node
    cloud-spec   → s3://bucket/store/n2x9          ← object store
```

Because ZFS encryption operates at the data level, what travels over the socket is already encrypted to the right keys. The transport doesn't need to know. The security boundary travels with the data.

**What this enables:**

- **Federation** — any node running the interpreter can be symlinked into your catalog
- **Replication** — write a `_save` that fans out to multiple peers
- **Caching** — write a `_read` that checks local before going remote
- **Failover** — write a `_read` that tries tcp first, falls back to local store
- **Remote generators** — `_cipher.generate` on a remote node returns into your local store
- **Cross-node cascades** — dependency updates propagate over sockets the same as locally

You're not choosing a transport. You're programming filesystem behavior. The socket is just one thing a directory can do.

---

## Signed Filenames and the Capabilities Language

The filename itself is a **signed, structured capability token**. Rather than a random opaque ID, the generator encodes identity into the name:

```
cipher(user_key, original_name, context) → "a7f2k9p3q1"
```

The result looks opaque. But it isn't random — it is signed. The structure is recoverable by anyone with the right key. This gives the filename three properties simultaneously:

- **Unique** — collision-resistant within the namespace
- **Attributed** — verifiably tied to the key that generated it
- **Structured** — recoverable metadata for the right reader, opaque otherwise

The generator behavior is programmable. For SolidWorks, filenames have no meaningful structure, so the value should be random — or more precisely, the original name is not worth encoding. But for a parts catalog, the cipher can encode part lineage, project context, revision history, or access tier directly into the filename. Same interface, different policy.

### Capability Views Over the Flat Store

Because filenames are signed and structured, different keys decode different views of the same flat store:

```
user key      → decrypts original filename + full metadata
project key   → decrypts part number + project context only
public key    → sees opaque ID, knows the file exists
no key        → file is invisible
```

The catalog is not just a symlink layer. It is a **view computed from your key set**. Two users mounting the same flat store see different catalogs — not because the data is different, but because their keys decode different structure from the same filenames.

```
Alice mounts store with [user_key, project_key, public_key]:
  /catalog/
    structural/main-bracket.sldprt
    fasteners/m6-hex-bolt.sldprt
    assemblies/door-assembly.sldasm

Bob mounts store with [public_key] only:
  /catalog/
    a7f2k9p3q1
    m4x8n2v6j5
    w9q1r7t4k2
```

Same files. Same flat store. Different capability views.

### VDNS — Virtual Distributed Namespace

The filename namespace IS the addressing system. Just as a Tor `.onion` address is the public key, a signed filename is a claim over content — verifiable, self-describing to the right reader, and globally addressable without a central registry.

The catalog is the DNS layer: resolving opaque addresses to human-readable names for whoever holds the right keys. Extended across nodes via the socket protocol, this becomes a **virtual distributed namespace** — VDNS — where:

- Every file is addressable globally by its signed ID
- Resolution is key-gated — you see what your keys allow
- No central registry — the math guarantees uniqueness
- Remote nodes are just directories with socket-backed `_read`/`_save`

```
flat store    ← signed filenames, globally addressable, opaque by default
catalog       ← per-key view, human readable, capability-gated
socket        ← same model extended to remote nodes
VDNS          ← catalog resolution across nodes, key-gated visibility
```

### Hide/Show as a Language

The capability structure falls out of the key set presented at mount time. This is not access control in the traditional sense — there is no policy file, no ACL, no admin to ask. The filesystem shows you exactly what you are capable of seeing. Nothing more.

Hiding a file means not encoding it into a key the viewer holds. Showing a file means encoding it into a key you share with them. Revoking access means rotating the key. The entire permission system is the cipher — defined once, enforced everywhere, programmable through the same `_` interface as everything else.

```
_cipher.generate.user-only     ← encode with my key only
_cipher.generate.project       ← encode with project key, visible to team
_cipher.generate.public        ← encode with public key, visible to all
_cipher.generate.tiered        ← encode with all three, different depths
```

The hide/show configuration is just which generator you called when the file was created.

---

## What This Is

| Layer | What it looks like | What it actually is |
|---|---|---|
| LUKS volume | Encrypted disk | Block-level ACS boundary |
| ZFS dataset | Storage pool partition | Cryptographic capability boundary |
| ZFS snapshot | Point-in-time copy | Patch algebra over state |
| Flat store | A folder of signed filenames | The heap |
| Signed filename | Opaque ID | Capability token — structured, attributed, recoverable |
| Catalog | Symlinked directories | Per-key view over the flat store |
| VDNS | Catalog resolution across nodes | Key-gated distributed namespace |
| `_read` / `_save` | Files in a directory | Per-directory kernel call handlers |
| `_` writes | Saving a file | Function calls |
| File contents | Arguments | Program input |
| Read result | File content | Return value |
| Cascades | Automatic updates | Reactive dataflow |
| Socket endpoint | A file in the catalog | Programmable remote behavior |
| FUSE layer | Filesystem driver | The runtime |

The filesystem is not storing programs. The filesystem **is** the program. The security is not enforced by policy. It is the structure. The permissions are not configured. They are the cipher.

---

## Relationship to Prior Work

| System | What it got right | What it missed |
|---|---|---|
| Plan 9 | Everything is a file, uniform interface | Files were inert — no live computation layer |
| Smalltalk | Everything is a live object, messages are the interface | Couldn't escape the image — rest of world couldn't talk to it |
| Unix pipes | Composition via stdio | Ephemeral — no persistent, addressable computation graph |
| IPFS | Content-addressed, distributed | No identity layer, no live cascade |
| LUKS | Cryptographic volume boundary | Coarse-grained — whole volume or nothing |
| ZFS | Snapshots, encryption, per-dataset granularity | No computation layer, no programmable call handlers |
| Pijul | Patch algebra, commutative history | Not a filesystem — requires separate tooling and workflow |
| Tor .onion | Public key is the address, no central DNS | Routing only — no filesystem, no capability views |
| Capability OS (KeyKOS, EROS) | Capabilities as the permission primitive | Required bespoke OS — couldn't live under existing applications |

Plan 9 made everything look the same. Smalltalk made everything live. Neither bridged to the existing world of applications.

This lives **underneath** the existing world. SolidWorks doesn't need to know. Any application that can write a file gets the runtime for free.

---

## Properties

- **The filename is the call** — no API, no library, just POSIX
- **The contents are the arguments** — any format, any application
- **Generators are composable** — pipe syntax, cascade triggers
- **Identity is a policy** — swap generators without changing the interface
- **Collaboration is structural** — every user is already their own namespace
- **Configuration is execution** — writing to `/fuse/` is programming the system
- **Introspection is free** — the directory listing is the interface definition
- **Any app works** — the complexity is entirely in the FUSE layer
- **Security is structural** — LUKS/ZFS enforce ACS cryptographically, not by policy
- **History is algebraic** — ZFS snapshots compose, invert, and commute as patches
- **The network is just a directory** — socket endpoints inherit the same `_read`/`_save` interface
- **The security boundary travels with the data** — encryption is at the data level, transport-agnostic
- **Filenames are capability tokens** — signed, attributed, structured for the right reader
- **The catalog is a view** — computed from your key set, not a fixed directory
- **Permissions are the cipher** — hide/show is which generator you called, not a policy you configured
- **The namespace is distributed** — VDNS resolves across nodes, key-gated, no central registry

---

## Open Questions

- **Generator registration** — how do generators get installed and versioned?
- **Cascade depth** — how do you bound cascade chains to prevent runaway propagation?
- **Generator failure** — what does FUSE return if a generator errors mid-save?
- **Key loss** — orphaned namespace if a cipher key is lost; recovery strategy?
- **Key rotation** — how do you re-sign existing filenames when rotating a key without breaking the namespace?
- **LUKS volume granularity** — how fine-grained should volume boundaries be? Per user, per project, per sensitivity tier?
- **Snapshot algebra formalization** — what is the full set of patch operations, and how are conflicts represented?
- **`_read`/`_save` trust** — who can write behavior-defining files, and how is that itself controlled?
- **Remote generator consistency** — if a generator runs on a remote node, how do you guarantee the same output as local?
- **Socket failure modes** — what does `_save` return if the remote endpoint is unreachable mid-write?
- **Cross-node cascade loops** — if node A cascades to node B which cascades back to node A, how is that bounded?
- **VDNS resolution conflicts** — if two nodes sign the same logical name with different keys, how is canonical identity established?
- **Capability revocation** — revoking a key orphans all filenames signed with it; what is the migration path?
- **View consistency** — if the catalog is a per-key view, how do you reason about the state of the store as a whole?
