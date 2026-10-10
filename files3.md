# Distributed Scene Graph OS — Design Notes

Oct 10, 2026 · @paul

## Identity and Namespace Layer

Identities live in `/etc/acs` as content-addressed directories — the directory name is a hash derived from the identity's public key, making the name itself a fingerprint. Human-readable names like `paul` and `ucryo` are symlinks into these hash dirs, but they are not mere aliases. Following Plan 9's model, they are namespaces: the logical layer through which operations and relationships are resolved.

Each identity directory holds:

- `_.pem` — public key
- `._.pem` — private key
- `_.hb` — heartbeat file, metadata about the identity
- Symlinks to federated identities (e.g. `paul/ucryo`)

File permissions carry responsibility, not just access control. Ownership of a file means accountability for decisions about it — the permission structure is a task assignment map, not a naive access list. Security in this system means integrity of process: ensuring the right person makes the right decision at the right time.

## Federation Model

Federation is peer-to-peer, not hierarchical. There is no root authority, no owner/contributor distinction baked into the structure. Each identity maintains its own namespace, grants regions to peers it trusts, and receives regions in peers' namespaces it can write into.

The symlink is the grant. When paul creates `paul/ucryo`, he is opening a bounded region of his namespace for ucryo to operate in. Ucryo holds `ucryo/paul` as its reference to where it is operating. Each party holds their side of the relationship in their own namespace. The cross-links are mutual trust bindings, not pointers.

This means:

- Paul can write into ucryo's domain; ucryo can write into paul's
- Capabilities are self-sovereign — paul defines what he possesses, federations certify them rather than reissue them
- A federation does not need to recreate paul's capabilities inside its domain; it endorses what paul already holds
- Revocation is clean — removing a symlink collapses the binding entirely

The `.hb` file in each federated directory captures the terms of that bilateral relationship. Trust is negotiated per pair, not governed by global policy. Adding a new identity to the network requires no central registry — only bilateral namespace grants with existing members.

## FUSE Coordination Layer

FUSE sits between applications and the filesystem, making the coordination layer invisible to clients. SolidWorks, or any other application, simply sees a local filesystem. What happens beneath that seam is entirely controlled by the FUSE driver.

**Checkout mechanics:**

1. Open for read — serve the file, no state change
2. Open for write — snapshot the current state, change file ownership to the requesting user, mark the origin read-only, hand a cache copy to the application
3. The ownership change *is* the lock — no separate lock database; the filesystem state expresses the coordination state
4. On file close, the FUSE driver calls the resolver defined for this context

The resolver handles what "done" means: overwrite origin, flag for review, merge, or something else entirely. The system does not pick — the context does. The resolver is the place where federation logic lives: it knows the relationship between participants and what they have agreed constitutes a valid resolution.

**Configuration** follows the standard Unix hierarchy. System-wide resolver policy lives in `/etc/fuse`; local overrides in `.fuse` directories closer to the work. A project directory can carry its own `.fuse` defining resolution behavior appropriate for that project. The `.fuse` config is composable — most-specific-wins — though the exact nesting mechanics are TBD pending more FUSE experience.

**Logging** is automatic. FUSE sees every interaction — open, read, write, close, stat — so the interaction log requires no manual instrumentation. Every act of work produces a record of that work as a side effect.

**Notebook multiplexing.** Files carry their own notebooks; users carry personal notebooks in their home directories. FUSE composes these into a unified view when relevant — a multiplexed stream correlated by the interaction log. The composition policy is also expressible in `.fuse`. No notebook needs to know about any other; FUSE provides the joined view.

## Encrypted Data Pools

Federated data lives in `/fed/` as a collection of encrypted LUKS volumes. Each volume's name is encrypted with the owning identity's ACS key — the name is only resolvable by someone with the right key. To any other observer, `/fed/` is a directory of opaque strings.

LUKS encryption operates at the block device layer, below the filesystem. This means:

- The encryption boundary is a sovereignty boundary, not a transport security mechanism
- You own your volume; you hold the key; what crosses a domain boundary is what you choose to share, decrypted on your terms
- A peer can store or relay your volume without being able to read it

**Three domain boundaries, three encryption contexts:**

| Domain | Purpose | Key |
| --- | --- | --- |
| Source | Data sovereignty | Owner's ACS key |
| Transit | Confidentiality in motion | TLS / WireGuard or similar |
| Destination | Receiver's sovereignty | Receiver's key |

The boundaries do not stack — you are not encrypting three times. You decrypt your data with your key, encrypt for transit, the receiver decrypts transit and works with what you sent. The number of crypto operations does not grow with the number of boundaries.

Transit is itself a sovereign domain. The carrier moves bytes without knowing what they are. With onion routing, each hop knows only its immediate neighbors — not the full path, not the payload, not the relationship between source and destination.

**ZFS / BTRFS send** moves data between domains efficiently and incrementally. The send operates on the open filesystem (you hold the key, you have access), so what travels is the data you chose to share. The encryption boundary stays intact because it is defined by key possession, not by what is transmitted.

## Lazy Knowledge Catalog

The catalog is not a list of what exists — it is a map of what is known relative to what is needed. Gaps are dependencies that have not been resolved yet, not absences.

The catalog is lazy in the precise sense: items are not fully evaluated until something depends on them. A desired outcome pulls on the catalog. If all dependencies exist and are defined, the outcome is achievable directly. If something is missing or underdefined, that gap surfaces as a project — the work required to fill the dependency.

**Ordering behavior:**

- Order an item that exists → fulfillment
- Order an item that is partially defined → modification or variant; does not spin up a new project domain
- Order an item that does not exist → new project domain; the act of ordering starts the definition process
- "I want this but like that" → fork or variant against an existing item; also valid

The inventory item carries enough context to distinguish these cases — whether it is fully defined, partially defined, has existing instances, or has prior modifications.

This approach naturally prioritizes work. What gets worked on is what is actually blocking a desired outcome, not what someone thought might be useful someday. The catalog is generative: gaps in it are latent projects waiting to be commissioned.

**Project coordination as documentation.** Rather than building a product and then writing a manual, the design intent is to write the manual for the thing you want to have and then build a product that conforms to it. The notebook system captures this automatically — design intent is recorded as work happens, through the same FUSE-logged interactions the system is being built to coordinate. The system documents itself into existence.

## The Graphics Engine as Prime Mover

The display is ground truth. Everything a computer does eventually resolves to pixels (or sound). The graphics engine is not a metaphor for the system — it *is* the system: a distributed scene graph resolving what needs to be on screen.

The engine asks for a pixmap. If the data needed to produce it is present, it renders. If not, the screen driver requests a fallback value. That fallback request propagates up the stack: what do I need to produce this? That in turn asks the same question of its dependencies. The pull propagates until it either hits something that exists or identifies a gap that requires work.

This means the entire system — tasks, projects, federation, inventory, coordination — is the dependency resolution chain of a graphics engine trying to produce a frame. There is no separate task manager, no separate project system, no separate catalog query interface. It is all one thing.

- The graphics engine's demand is the query
- The catalog is the scene graph
- The gaps are the work
- The OS is the first level of resolution — what does the screen need? The OS. What does the OS need? Everything else follows

A scene graph is already lazy, hierarchical, and dependency-resolved by nature. You do not compute what is off screen. You do not evaluate what is occluded. You resolve only what is needed to produce the current frame. The knowledge catalog is the same structure extended to arbitrary work.

Distributed means the graph does not live on one machine. Nodes live wherever they live; the engine composites them into coherent output. The federation and FUSE layers are the mechanism by which a distributed scene graph produces a single coherent frame across domain boundaries.
