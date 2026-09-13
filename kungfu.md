# ACS — Addressed, Cryptographic, Sovereign

A distributed operating system built from first principles around ownership.

## What it is

ACS is a distributed filesystem and identity layer where ownership is architectural, not policy. The core idea: location is an implementation detail. Everything is an address. The distinction between a register address, a disk address, and a network address is just a different lookup in the same unified address space.

Identity and privacy are the same thing — a cryptographic boundary you control. Every transaction occurs on a cryptographic channel derived from an ed25519 keypair. The keypair is the node. You cannot be identified to the system without participating in the handshake. There are no shadow profiles, no ambient tracking, no inference. The default is closed. Openness requires active participation.

## Current state

A working process exists. The bootstrap script does the following in sequence:

- Generates an ed25519 keypair
- Derives the node's address (`ch`) from a hash of the public key — content addressing from the start, location-independent by definition
- Creates a LUKS2 encrypted volume keyed to the private key, so the cryptographic identity and the storage boundary are the same object
- Mounts a ZFS pool on that volume, inheriting ZFS's snapshot, checksumming, and send/receive semantics
- Takes an initial snapshot and renames it by hash — every state transition is addressable and verifiable
- Begins watching for write events via `fatrace` to trigger frame boundaries

A lazy directory listing service provides the beginning of the protocol layer, with cursor-based pagination and generation tokens for cache invalidation.

## Namespace topology

The system is organized around a small set of namespaces:

- **`re`** — real state. The rendered, instantiated, observable filesystem at this moment.
- **`im`** — imaginary state. Stored behaviors, policies, and configurations waiting to be instantiated. Not currently executing, but defining the envelope of what can happen.
- **`acs`** — access control system. The key management layer. Cross-correlates namespace paths and gateway addresses with capabilities. The binding layer where identity, location, and capability meet.
- **`gw`** — gateway. The boundary layer between inside and outside the cryptographic envelope.
- **`fed`** — federation. How multiple envelopes relate to each other.

The `re`/`im` distinction is modeled on the physics analog of state space. A node is fully described by where it is in `re` space right now plus the behavioral envelope in `im` that defines how it can evolve. Both are required. The keypair determines what `im` states can be instantiated by this identity.

## Snapshot model

ZFS snapshots are points in `re` space. The send/receive protocol is movement through it. Frame trigger policies — expressed as filesystem paths (`every.{sec}`, `written.{size}`, `on.close}`) — define the grammar of how that movement happens. The directory structure is the configuration language.

## Trust and federation

Within a single node, `acs` is local. When two nodes interact through `gw`, their `acs` layers negotiate — not merge. Each identity retains sovereignty over its own capability definitions. The intersection of what each is willing to grant the other is the protocol of trust between nodes. Because it is cryptographically grounded, this trust is verifiable, not social.

## What this is not

This is not a platform. There is no central server, no operator, no terms of service, no engagement metric. The incentive structure of the infrastructure is aligned with the people using it because those people own it — architecturally, not as a governance abstraction.

## License

MIT
