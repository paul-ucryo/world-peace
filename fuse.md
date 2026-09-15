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

## What This Is

| Layer | What it looks like | What it actually is |
|---|---|---|
| Flat store | A folder of opaque filenames | The heap |
| Catalog | Symlinked directories | Scoped namespaces / indexes |
| `_` writes | Saving a file | Function calls |
| File contents | Arguments | Program input |
| Read result | File content | Return value |
| Cascades | Automatic updates | Reactive dataflow |
| FUSE layer | Filesystem driver | The runtime |

The filesystem is not storing programs. The filesystem **is** the program.

---

## Relationship to Prior Work

| System | What it got right | What it missed |
|---|---|---|
| Plan 9 | Everything is a file, uniform interface | Files were inert — no live computation layer |
| Smalltalk | Everything is a live object, messages are the interface | Couldn't escape the image — rest of world couldn't talk to it |
| Unix pipes | Composition via stdio | Ephemeral — no persistent, addressable computation graph |
| IPFS | Content-addressed, distributed | No identity layer, no live cascade |

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

---

## Open Questions

- **Generator registration** — how do generators get installed and versioned?
- **Cascade depth** — how do you bound cascade chains to prevent runaway propagation?
- **Network stores** — how does the flat store behave across machines, sync conflicts?
- **Generator failure** — what does FUSE return if a generator errors mid-save?
- **Permissions** — who can register a generator, and how is that itself controlled?
- **Key loss in cipher generators** — orphaned namespace if the key is lost; recovery strategy?
