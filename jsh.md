# JSH — JSON Shell as Universal OS Interface

Oct 15, 2026 · @paul

## Overview

JSH is a JSON-based shell image format that treats the operating system as a composable vector space. A `.jsh` file is not configuration — it is a serialized execution environment that, when loaded, enacts state changes across any substrate it addresses: filesystem, database, network, UI. Loading a jsh is running it. The file is the program.

The core insight is that namespaces, file paths, JSON keys, SVG ids, database tables, and variable names are all projections of the same underlying structure — a discrete potential field — rendered into different substrates. JSH makes that structure explicit and portable, so the same logical description can drive any runtime without modification.

## The namespace model

A particle in physics and a node in a digital logic tree are not analogous — they are the same structure: a discrete potential field with quantized state transitions. The substrate differs; the mathematics does not. A variable, a file, a database row, an SVG element, and a quark are all nodes in a potential field whose state space is countable and whose transitions are rule-governed.

This is not metaphor. "Discreteness" is the property that makes digital logic digital. It is also the property that makes a particle a particle rather than a continuous wave. The namespace is the field. The key is the handle into it. The value is the occupied state.

At different scales, the semantics shift — but the structure does not. A single JSON key at one scale is a node in a service graph at another. A file is a namespace segment. A variable is a particle. Programs are to chemistry what variables are to particle physics: compound structures whose emergent behavior arises from binding, not from the primitives themselves. Understanding the primitives tells you why and how the compound behaves — and how to engineer the process.

Querying this structure is spectroscopy. You tune the instrument to a frequency — an ownership graph, a data-flow graph, a physical topology — and read what fluoresces. The same underlying graph emits differently depending on what you are looking for and at what resolution. A type system is spectroscopy: a type describes which energy states are occupied and which transitions are permitted. Type-checking verifies that the emission spectrum of one term matches the absorption spectrum of what receives it.

## The jsh file format

A `.jsh` file is valid JSON. It is also a live interface to the system: loading it applies its contents as side effects at the locations its URIs address. The file is simultaneously a snapshot and a script.

```json
{
  "env": {
    "fs": "file system",
    "catalog": "/fs._.catalog"
  },
  "${catalog}": {
    "partNo": {}
  },
  "design.svg": {
    "xmlns": "http://www.w3.org/2000/svg",
    "viewBox": []
  },
  "": ""
}
```

**env** defines the resolution rules — the PATH of this shell. Each env entry is an alias: `${catalog}` anywhere in the file expands to the value bound in env. The mount point `_` is the root of the shell's world, analogous to `~` or `/`. `_.catalog` means the catalog resource relative to the mount point.

**URI prefixes** name the substrate. `/fs` means resolve against the filesystem. `/http`, `/db`, or other prefixes invoke their respective drivers. The runtime selects the driver based on the prefix; the rest of the path is handed to that driver unchanged.

**Key-value pairs** are instructions. A key with a concrete value is a write: go to that URI and make it look like this. A key with a reference (`${...}`) is a read: go to that URI and return the current value. The jsh is bidirectional — it describes what to change and what to observe.

**Empty string keys** (`"": ""`) are deferred slots: parts of the namespace not yet resolved, waiting for the runtime or the user to supply the missing bindings. The jsh is a partial snapshot; the blanks are lazy expressions.

**Dot notation in keys** maps to path structure. `design.svg` means look in the `design` namespace for the `svg` resource. The extension in the key hints at the format: `.svg` resolves to an SVG file, no extension resolves to a JSON object. The key is the query; the substrate is the database.

## The vector model

Each jsh file is a vector in system state space. Running it is a linear transformation: the current system state multiplied by the jsh matrix produces the new state.

- `1.jsh` is a transform matrix applied to the initial state
- `2.jsh` is a second transform applied to the result
- Running them in sequence is matrix composition — associative, ordered
- Order matters: jsh multiplication is not commutative, just as matrix multiplication is not

This has direct practical consequences:

**Composition before application.** Two jsh files can be multiplied together before running — producing a single transform that takes the system from any start state to the desired end state in one pass. A pipeline of jsh files is a sequence of matrix operations that can be precomputed.

**Inversion.** A jsh has an inverse — the transform that undoes it. This is rollback. If `2.jsh` moved the system to state B, the inverse of `2.jsh` moves it back to state A. No separate undo mechanism is needed; it falls out of the algebra.

**Idempotence.** A jsh whose transform is the identity matrix (it reads everything and writes nothing new) is a no-op. Running it twice produces the same result as running it once. Idempotent jsh files are safe to replay.

**History as a basis.** A sequence of jsh files forms a basis for the system's state space. Any past state is a linear combination of the transforms that produced it. Replaying the sequence from the beginning reconstructs the system at any point in time — this is version control as a special case of linear algebra.

## FUSE integration

FUSE (Filesystem in Userspace) is the natural mount layer for jsh. A jsh file mounted via FUSE becomes a live filesystem: the OS handles all the routing, and any program that speaks filesystem can interact with the shell image without knowing jsh exists.

**Opening the image** — FUSE mounts it, queries all URIs defined in env, and assembles the live view. Each key in the jsh appears as a file or directory in the mount.

**Reading a file** — FUSE resolves the reference and returns the current value from wherever it lives. A read of `catalog/resistors` fetches from `/fs._.catalog/resistors` transparently.

**Writing a file** — FUSE intercepts the write, parses the change, and routes it to the correct URI. The write is a new jsh delta applied to the current state.

**Unmounting** — flushes pending writes, snapshots the current state as a new jsh file. The shell image is consistent on close.

Because it is FUSE, the runtime is invisible. Any editor, any shell script, any program that reads and writes files can use it. The jsh protocol does not need to know about any of them — it just needs to correctly implement the FUSE handlers for the substrates defined in env. The compose/parse system that implements those handlers is the entire runtime. Once it is stable, the interface is universal.

## CRDT and streaming

A jsh file is a CRDT (Conflict-free Replicated Data Type) by structure. Each key is an independent unit addressed by a URI. Because every key maps to exactly one location, merging two jsh files produces no ambiguity — each key's value is either the same in both files (no conflict) or different (last-write-wins per key, deterministic). The URI is the conflict-resolution key.

This makes jsh streamable. You can pipe a sequence of jsh files into a FUSE mount and the system converges to the target state incrementally:

```sh
cat 1.jsh 2.jsh 3.jsh | jsh apply --mount ./env
```

Each jsh in the stream is a delta. The system reaches the final state after all deltas are applied, regardless of intermediate states. If the stream is interrupted, the system is in whatever partially-applied state the last complete jsh left it — no corruption, because each jsh is atomic at the key level.

**Time travel** falls out naturally. Every jsh in a sequence is a commit. The state at any point in time is the composition of all jsh files up to that point. Replaying them from the beginning rebuilds the system at any commit. Rolling back is loading an earlier snapshot. Branching is forking the sequence and letting two jsh streams diverge independently.

This is git — but the diff format is the entire system interface, and it applies live.

## OS as distributed vector system

The OS is not a privileged layer — it is a collection of resources addressable by URI, each with a state space and a set of permitted transitions. Disk, CPU, memory, network, and compute nodes are all nodes in the same graph. JSH treats them as composable vector attributes of a single state space.

Each resource type is a dimension in the vector space:

| Dimension | URI prefix | State | Transitions |
| --- | --- | --- | --- |
| Filesystem | `/fs` | file contents, permissions | read, write, delete, move |
| Process | `/proc` | running, stopped, exit code | spawn, signal, wait |
| Memory | `/mem` | allocated, mapped regions | alloc, free, map |
| Network | `/net` | open sockets, connections | connect, send, recv, close |
| Compute | `/gpu`, `/cpu` | kernel loaded, registers | dispatch, sync |
| Remote node | `/ssh.host` | same as above, remote | same transitions, tunneled |

A jsh that addresses `/proc`, `/fs`, and `/net` simultaneously is orchestrating across all three dimensions in one atomic transform. The system moves from one state to another as a single vector operation — not a sequence of shell commands.

Distributed systems are the same model at larger scale. A cluster of nodes is a higher-dimensional vector space where each node contributes its own dimensions. A jsh that addresses `/ssh.node1.fs._.data` and `/ssh.node2.proc.worker` is a distributed transform — one file, one operation, multiple machines. Orchestration tools like Kubernetes are implementing a subset of this model with bespoke syntax; jsh generalizes it to any substrate any URI prefix can address.

Debugging in this model is analytical chemistry: you are not tracing execution, you are identifying which state transition produced an unexpected compound. The jsh history is the reaction log.

## The SVG schematic use case

The schematic pipeline is a concrete instance of the jsh model. A design table is a view into the namespace. The SVG is another view. The parts catalog is a third. None of them own the data — they are all projections of the same underlying graph.

**Parts catalog.** Each part is a node in the namespace with a URI as its address. The part does not own its symbol — it holds a query over the symbol library. `"symbol": "symbols/resistor.svg"` is a reference, not a copy. Hundreds of resistor variants all point to the same drawing. The catalog is the namespace index; the symbol library is a separate, stable namespace the catalog queries into.

**SVG symbols.** Each symbol lives in its own file with its own `viewBox` — its own coordinate namespace. The `viewBox` is the canonical coordinate system for that symbol; `width` and `height` are output concerns. Port positions are defined in the symbol's coordinate space and travel with it. A `<symbol>` + `<use>` pattern lets the runner inject only the symbols actually needed for a given schematic into `<defs>`, then place instances.

**The jsh schematic file.**

```json
{
  "env": {
    "fs": "file system",
    "catalog": "/fs._.catalog",
    "symbols": "/fs._.symbols"
  },
  "${catalog}": {
    "partNo": {}
  },
  "design.svg": {
    "xmlns": "http://www.w3.org/2000/svg",
    "viewBox": [-10, -10, 200, 100]
  }
}
```

The runner is almost nothing: load jsh, resolve env, query referenced parts, inject symbols into `<defs>`, interpolate fstring hints into SVG templates for each component, emit the file. All the logic is in the jsh. The runner is a traversal.

**Fstring hints** are deferred expressions in the snapshot — parts of the state not yet resolved, waiting for the runtime to supply the missing bindings. They are not templates in the traditional sense; they are lazy fields in a partial snapshot. The distinction matters: a template is a program, a deferred field is data. The jsh stays data all the way down, which is what makes it substrate-agnostic. The same jsh file can be executed by Node, Haskell, bash, or a FUSE driver — each is just a traversal of the same namespace tree with its own runtime supplying the bindings.
