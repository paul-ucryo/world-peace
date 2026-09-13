# ACS VCS — Version Control as Vector Algebra over Address Space

## The core idea

Conventional version control treats history as a sequence of snapshots or a graph of deltas against a canonical base. Both models centralize something — either the snapshot store or the merge authority.

ACS VCS treats the filesystem as a vector space over the address space. Changes are vectors. Composition is addition. Conflict is non-commutativity. The diff engine is ZFS copy-on-write send/receive.

This is the same insight as Pijul — that patches should form a commutative monoid so that merge order doesn't matter — but grounded directly in the filesystem's native CoW semantics rather than an abstract patch theory implemented on top.

## ZFS CoW as the diff engine

ZFS never overwrites data. Every write produces a new block. Snapshots are free — they are just a reference to the current block tree at a point in time. `zfs send` produces a stream of the blocks that differ between two snapshots. This is not a diff in the traditional sense. It is a precise description of the transformation between two states in the address space.

```bash
zfs snapshot pool@a
# ... writes happen ...
zfs snapshot pool@b
zfs send pool@a pool@b > a_to_b.stream   # the vector from a to b
```

The send stream is the vector. It is:

- **Complete** — it describes exactly what changed, at block resolution
- **Verifiable** — ZFS checksums every block
- **Composable** — `zfs receive` applies the vector to any compatible base state
- **Cheap to produce** — CoW means the blocks already exist, send just enumerates them

## Address space as vector space

Every file, every block, every node in the system has an address. The state of the system at any moment is a point in that address space. A commit is a vector — a displacement from one point to another.

In a true vector space:

- **Addition** — applying two vectors to the same base state. If they commute, order doesn't matter. If they don't, that non-commutativity is the conflict, and it is algebraically precise rather than heuristic.
- **Identity** — the zero vector, no change
- **Inverse** — `zfs send` in reverse, undoing a transformation exactly

The `im` layer stores vectors — pending transformations waiting to be applied. The `re` layer is the current point in the space. A commit moves `re` by applying a vector from `im`.

## Frames

A frame is a bounded unit of change — the vector between two snapshots. Frame boundaries are determined by policy stored in the filesystem itself:

```
every.{sec}/
written.{size}/
on.close/
```

Each policy directory defines a trigger. When a trigger fires, the current `re` state is snapshotted, a send stream is produced against the previous snapshot, and that stream is addressed by the hash of its content. The frame is now an immutable, addressable object in the address space.

```bash
zfs snapshot pool@new
zfs send pool@prev pool@new | sha256sum   # content address the vector
zfs rename pool@new pool@<hash>
```

## Federation as vector composition

When two nodes exchange state, they exchange vectors — send streams addressed by hash. There is no canonical base, no central repository, no merge authority. Each node maintains its own `re` state and applies incoming vectors against it.

Conflict is detected algebraically. Two vectors commute if applying them in either order produces the same result. If they don't commute, the non-commutativity is the conflict — not a heuristic judgment about line proximity, but a precise statement about which blocks they both wrote.

Resolution is explicit vector composition. The user produces a new vector that describes the intended merged state directly, without reference to a canonical version.

## Identity and ownership through the VCS layer

Every send stream is produced on a cryptographic channel. The vector is signed by the identity that produced it. Receiving a vector means verifying that signature against the `acs` layer — does this identity have write capability at these addresses?

Provenance is therefore intrinsic. Every block in the address space carries the identity of who last wrote it, verified cryptographically, without a separate audit log.

## Relationship to Pijul

Pijul implements patch commutation theory in software on top of a conventional filesystem. ACS grounds the same algebraic structure in the filesystem's native CoW semantics. The diff engine is not implemented — it is the storage layer itself. This means:

- No translation layer between storage and version control
- Block-level granularity rather than line-level
- Verification is storage verification — the same checksums that ensure data integrity ensure patch integrity
- The address space is unified — a version is not a separate object from the filesystem state, it is the same address space at a different point

## Content addressing by hash

If an object is addressed by the hash of its content, the same data will always produce the same address. This is not just a naming convention — it is a structural property of the address space with several consequences that don't need to be separately implemented.

**No duplication.** Two nodes that independently produce the same state arrive at the same address. Writing that state twice writes nothing — the address already exists. Deduplication is not a feature layered on top, it is what content addressing means.

**Natural lookup table.** The address space is a hash table over all content that has ever existed in the system. Any object can be located by anyone who knows its hash, without a directory, without a registry, without a central index. The hash is the location.

**Provenance without metadata.** If two vectors produce the same send stream they have the same hash and are therefore the same vector, regardless of who produced them or when. Identity of content is identity of address. You cannot have two different objects at the same address, and you cannot have the same object at two different addresses.

**Garbage collection without a collector.** An object is live if something holds a reference to its hash. An object is dead if nothing does. There is no reachability analysis, no mark-and-sweep, no separate GC pass. Reference counting over the address space is GC. When the last reference to a hash is deleted, the object is unreachable by definition — not by policy, not by a background process making a judgment, but because the address is no longer in anyone's namespace.

**Verified by default.** Locating an object by hash and receiving it is the same operation as verifying it. If the content hashes to the address you requested, it is correct. If it doesn't, it isn't. There is no separate verification step because the address is the verification.

This is why the frame hashing in the snapshot model is not just bookkeeping. Each frame's send stream addressed by its own hash means the version history is a content-addressed graph. Older states are not deleted — they remain at their addresses as long as anything references them. States that nothing references disappear without any explicit deletion. The history is self-organizing.

## Current state

ZFS snapshot and send/receive are working. Frame trigger policies are defined. Content addressing of send streams by hash is implemented. Federation and algebraic conflict detection are next.
