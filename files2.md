# Federated Domain Architecture

i don't agree with this 100%. I'd do a dynamic journal, like smalltalk in text files, not the audit that this porpose.

## Core Idea

Plan 9 namespace composability over a distributed content-addressed store. Location is irrelevant — presence is a pointer. Every domain is a view over content hashes.

## Primitives

### Content-Addressed Store
All data lives in a distributed store addressed by content hash. Restic manages the storage layer — deduplicating, encrypting, snapshotting incrementally. The store is the ground truth.

### Two Layers

**Metadata**
- Structured, queryable, semantic
- Indexes, logs, relationships, schema
- What you reason over
- Cheap to query — payload never touched

**Payload**
- Raw binary blobs
- Content addressed
- What you store

Both are independent Restic snapshots. Each deduplicates and snapshots incrementally on its own cadence.

### Symlinks
Symlinks compose metadata and payload into a deliverable. Metadata points at payload chunks. Together they present a coherent domain to the consumer. Swap either layer independently — the other doesn't move.

## Domain Structure

A domain is a namespace instantiated under `/fed`:

```
/fed/
  <domain>/
    sys/        → symlink to sys repo
    budget/     → symlink to budget repo
    design/     → symlink to design repo
    catalog/    → symlink to catalog repo
    inventory/  → symlink to inventory repo
    mbus/       → symlink to message bus
    log.jsonl   → append-only audit log
```

Creating a directory under `/fed` triggers a FUSE hook that forks the domain template and sets up the bind mounts. Presence equals participation.

## Audit

The audit trail lives in the content, not the tool. Each domain carries an append-only structured log:

```json
{"ts": "2026-09-23T08:00:00Z", "actor": "actor", "action": "created", "target": "fed/domain", "reason": "reason"}
```

Who changed what, when, and why is a metadata concern — just another file in the domain, snapshotted with everything else.

## FUSE Layer

The FUSE daemon is the Plan 9 binding mechanism. It:

1. Watches `/fed` for new directories
2. Forks the domain template
3. Sets up bind mounts
4. Registers the domain (DNS, identity)

The mounted domain directory is the live system. The namespace is the interface.

## Everything Is Pitch

RAM, ROM, CPU, git, ZFS, DNS — all namespaces over address space, all pitch behaving differently under different constraints. This architecture makes pitch the primitive. The constraint is a parameter, not a new tool.
