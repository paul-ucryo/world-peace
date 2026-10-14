# ACS: Federated Filesystem Design

Aeris OPS LLCAeris OPS LLCAeris OPS LLCOct 14, 2026 · @paul

## Overview

ACS (Access Control System) is a federated filesystem built on the principle that coordination and ownership are separate concerns. Every resource is content-addressed, every identity is cryptographic, and trust propagates organically through contribution rather than assignment. The system is designed so that no single actor can dominate coordination regardless of how many physical resources they own.

The design is inspired by Plan 9's namespace philosophy: the same navigation logic plugs into any payload backend, and federation falls out naturally from symlinks crossing cryptographic trust boundaries — no special federation protocol needed.

## Filesystem Architecture

The storage layer is a LUKS2 encrypted volume containing two top-level directories:

- `logic/` — symlinks, config files, and namespace structure. Small, cheap to snapshot, easy to query without touching binary data. This is the VCS log equivalent.
- `payload/` — binary blobs and large data. Content-addressed. The symlinks in `logic/` point here. This is the object store equivalent.

Switching "branches" means changing which snapshot of `logic/` is active. The payload is never touched until a file in the resolved namespace is actually accessed — lazy by design.

**Versioning** is handled by Restic, which provides a CAS-backed snapshot store (Blake2 content addressing, deduplication, multiple backends). Each domain runs its own Restic repo under `.audit/`. Restic snapshots serve as the proto-patch system until a full CRDT layer is added later.

**Session switching** is managed via a `_.session` symlink that points to the active session definition. Anything with write access to that symlink — a cron job, a FUSE trigger, a network event — can switch the active session. No login daemon required.

**Future:** LMDB replaces flat config files for small frequent metadata (session state, presence, routing tables) once flat files show limits. Large blobs stay in Restic/payload.

## ACS Key and Trust Model

Every LUKS volume is keyed with either the public or private half of an asymmetric keypair. Which key encrypts the volume determines the sharing model:

- **Public key as symmetric key** — anyone with the public key can mount and read. The private key signs writes, providing authorship and audit. Wide read, controlled write authority.
- **Private key as symmetric key** — only the private key holder can mount and read. The public key authorizes writes from external contributors. Restricted read, open write authorization.

The LUKS header itself encodes which model is in use — no separate config needed. If you can mount with the public key, it's a public-read volume.

Keypairs live in `/etc/acs/.{id}/`. This is the local identity store, hidden by default. The `/etc/acs/{domain}/` directories are symlinks into `.{id}/` entries — the federated trust namespace, expressing "who is trusted in this domain" as a symlink graph.

**Capability semantics:** Possessing the key is the permission. There is no ACL layer to misconfigure and no privileged process to exploit. Content written without the write key is technically possible at the block level but is semantically invisible to the system — it cannot be read, so the GC eventually collects it. This is not access control; it is scope definition. Content outside the scope is not invalid, it is simply in a different scope, like non-TLS traffic on a network that uses TLS.

## Session and Presence System

`_.session` is both the login mechanism and the live presence board for a shared resource.

**Before authentication:** mounting the SMB share shows only `_.session`. Opening it and writing credentials causes the FUSE driver to intercept the write, validate, and mount the appropriate session. The write IS the login — no separate auth dialog, no special client needed. Any SMB client that can open and edit a file can authenticate.

**After authentication:** `_.session` shows all currently active sessions on the shared resource. Each entry is keyed by `{user}@{terminal/station}` with a record like:

```
{user}@{terminal}: {
  target: {domain}
  token: {token, possibly encrypted}
  uptime: {}
  status: {active|idle|stale}
}
```

**Session states:**

- **Active** — domain mounted, credentials valid, payload accessible
- **Stale** — credentials still present, payload unmounted due to inactivity, namespace still visible
- **Gone** — credentials expired or removed, fully unmounted

FUSE write triggers or cron jobs handle auto-unmount on inactivity. The namespace stays live during stale state — accessing a file in an unmounted domain triggers transparent remount if credentials are still valid. `_.session` reflects all three states, giving a richer presence picture than a simple online/offline indicator.

**File locking** works the same way: a user opening a file in SolidWorks causes FUSE to write a presence entry. Everyone with read access to that domain can see the file is checked out. This is a visibility signal, not an enforcement lock — anyone can open the same file, and the CRDT layer handles merge on close. It makes conflict visible rather than trying to prevent it.

## Domain Structure

Every domain — a project, a company, a building, a customer request — has the same internal layout:

```
{domain}/
  design/
  inventory/
  catalog/
  budget/
  schedule/
  msg/
  .acs/       ← keys, _.session, auth
  .gw/        ← contacts, full project index, external identities
  .audit/     ← restic repo, full version history
```

The contents reflect the scope of the domain. A company `budget/` is the whole company budget. A project `budget/` is that project's slice. A building `inventory/` is physical assets. The shape is identical everywhere — scope determines the contents.

**Active projects** appear as top-level non-hidden directories in the home view. Inactive or archived domains live in `.gw/` and are accessible but not surfaced by default.

**The company home view** after authentication:

```
project-a/
project-b/
building/
budget/
schedule/
.acs/
.gw/
```

Projects and shared company resources are first-class at the root. System plumbing is hidden. The directory listing is the workspace.

**Incoming requests** (e.g. from a contact form) create a new domain keyed to the requester's identity. That domain IS the ticket — no ticketing system needed. Responding to it, attaching files, assigning it, and closing it are all just filesystem operations on that domain. History is the `.audit/` log.

## Federation Model

Federation is expressed as symlinks crossing cryptographic trust boundaries. No special federation protocol is needed — the symlink IS the federation mechanism.

**`/fed/{domain}/`** is the outward-facing published face of a domain. It contains only what the domain owner has explicitly symlinked in — public key, published namespaces, contact/presence info. When another domain adds you to their `.gw/`, they point at your `/fed/{domain}/` entry, not your internal `/etc/acs/{domain}/` directly.

**`.gw/`** is the domain's address book and federation map. External identities — customers, vendors, partners — are symlinks into `/etc/acs/.{id}/` for those entities. The contact list IS the federation graph.

**Cross-boundary symlinks** in the logic volume allow a namespace in one trust scope to reference payload in another:

- Your logic volume (your key) contains a symlink pointing to someone else's payload (their key)
- Their logic can reference your payload
- Each party maintains their own namespace; content crosses boundaries via pointer, not copy
- The FUSE driver resolves the symlink tree at access time — no data moves until needed

**Local caching** for remote connections works like a package manager: your `.gw/` defines subscriptions to remote domains, and a local cache stores your delegated slice. Restic handles sync and merge on reconnect. The local cache is just another branch in the audit trail.

**Roles are emergent:** contributing to `design/` in a domain makes you a designer in that domain. Others in their trust network recognize that by symlinking you into their `.gw/` as a design resource. No manager assigns roles; contribution and recognition propagate the trust graph organically.

## Economic and Coordination Principles

The system is designed so that stake (resource ownership) and trust (coordination authority) are completely decoupled. This is a first-class design constraint, not an emergent property.

**Stake is ownership of physical resources** — machines, buildings, materials, capital. It is real and not contested. The bankroller of a project controls what happens to the resources they own.

**Trust is coordination authority** — who works on what, what direction a project takes, whose contributions are incorporated. Trust is earned through contribution and reputation in the network. It cannot be bought with stake.

A large stakeholder who behaves badly still owns their resources but loses network participation. A small contributor with good work and reputation can have more effective influence in the trust network than a large stakeholder who extracts without contributing. The two systems coexist but do not collapse into each other.

**Extraction is visible to the person it is happening to.** Because audit history is in `.audit/` and the domain structure is transparent to participants, anyone can see what flows in and out of a domain — who gets paid for what contribution, and whether value extracted exceeds value added. Participation becomes a conscious choice.

**Monopoly capture requires controlling coordination.** Coordination in this system is decoupled from resource ownership, so a dominant resource owner cannot prevent a competing provider from emerging. Customers who can see extraction costs and contribution ratios can fork their own provider. The incumbent's only real defense is providing genuine value.

**The fork is always available.** If a resource owner pushes a direction the trust network rejects, the network forks. The owner keeps their physical resources. The network continues with what it has — the coordination graph, the contribution history, the trust relationships. Neither side can dominate the other because they operate on different axes.

This makes the system applicable to any captured market — insurance, pharma, housing, energy — where capture depends on tying coordination to resource ownership. Decouple them and the moat disappears.

## Primary Use Case: Healthcare Co-op

Healthcare is the first target system because it is the clearest example of coordination capture — the monopoly does not hold resources independently, it holds the coordination layer. Insurers, hospital networks, and pharmacy benefit managers extract value primarily by controlling who can participate with whom, not by owning anything that cannot be replicated.

**The problem:** Healthcare costs in the US are dominated by administrative overhead, insurer margin, and monopoly pricing enforced through network exclusivity. A co-op or union attempting to self-insure or pool purchasing power hits the same wall repeatedly — the incumbent controls access to the provider network, the formulary, and the claims infrastructure. Members cannot see what they are actually paying for or compare it to alternatives.

**How ACS addresses it:**

A healthcare domain in ACS looks like any other domain in the system:

```
healthcare-coop/
  design/        ← benefit plan design, formulary, coverage rules
  inventory/     ← provider network, facilities, equipment
  catalog/       ← procedure pricing, drug pricing, negotiated rates
  budget/        ← pooled funds, claims, actuarial data
  schedule/      ← appointments, utilization planning
  msg/           ← member communications, care coordination
  .gw/           ← member identities, provider identities, vendor relationships
  .audit/        ← full claims history, transparent to members
```

**Pooling across** individuals and networks: Any individual or trust network federates by symlinking into other domains via `.gw/`. An individual nurse, a teachers' network, and a small business owner can pool their `inventory/` (provider network) and `catalog/` (negotiated rates) without merging their `budget/` or `design/`. Each retains their own decisions and relationships while sharing the trust network's accumulated leverage. The symlink graph expresses the arrangement — no central authority, no enrollment, no group membership required.

**Extraction is** personal. You see it because it is happening to you — the `catalog/` pricing, the `budget/` flows, and the `.audit/` claims history. Not as an abstract audit, but as your own domain view: what you are paying, what you are receiving, and what the delta is. If a vendor or administrator is taking more than they contribute, you see it in your own context and you can act on it.

**Provider participation:** A provider joins the network by contributing to `inventory/` — listing their services, rates, and availability. The co-op's `.gw/` decides whether to reference that provider. No credentialing bureaucracy gatekeeps participation; the trust network evaluates on outcomes and pricing. A provider with good outcomes and transparent rates gets referenced widely. A provider extracting above market rates gets forked around.

**Against the incumbent:** The incumbent insurer still owns its brand and its existing contracts. What it cannot do is prevent the co-op network from forming, because the co-op's coordination layer is not dependent on the incumbent's infrastructure. Members who can see their actual costs and compare them to the co-op's rates make a straightforward economic decision. The moat disappears when coordination is decoupled from ownership.

**Path to viability:** Start with a single union or employer group self-insuring through the domain structure. Use the transparent `catalog/` and `.audit/` to demonstrate cost savings to adjacent groups. Federation via symlinks lets neighboring co-ops join without merging governance. The network grows organically as groups subscribe, exactly as the trust model describes — contribution and demonstrated value, not top-down enrollment.

**Organic growth path:** The system does not require any group formation. It starts with individual actors making individual decisions and grows as each actor's trust network expands.

1. **Non-certified coordination** — exercise groups, nutrition advice, peer wellness support. No licensing, no liability, no barrier to entry. Members contribute to `design/` and `msg/` freely. This is the seed domain.
2. **Provider advice networks** — members begin referencing trusted practitioners informally. Pricing transparency via `catalog/` lets the network compare actual costs. Providers with good outcomes and fair rates get referenced widely; others do not.
3. **Care services** — the network has enough pooled trust and member data to negotiate directly with providers. Group purchasing on prescriptions, lab work, imaging. The incumbent's negotiated rates are no longer the only option.
4. **U****n****i****v****er****sal ****coverage union** — sufficient pooled membership to self-insure against catastrophic risk, with reinsurance purchased at group scale. At this point the domain is functionally an insurer, but owned and governed by its member network with full audit transparency. The entire population can be covered because the network health is optimized with full participation and each member is incentivized to support the network since its in their best interest to maintain a healthy functioning system. Always.

Each step is an individual decision — not a group vote, not an enrollment. An individual sees the extraction in their own domain view, finds or forks a better option, and references it in their trust network. Others in that network see the same data and make their own decisions. The network must respond to every individual actor because every individual actor can see everything and act on it independently.

**The core reframe:** This is not a union or a co-op. It is a federated distributed trust network where every individual is a first-class actor. The same coordination infrastructure that brokers and insurers use to extract value from a fragmented, individually powerless customer base is available to every individual in the network. You do not need to join a group to access group leverage — you need to see what is happening to you and be able to act on it. The extraction is visible not because the system enforces transparency in the abstract, but because you are a participant and the system shows you your own participation. You see it because it is yours. Employers became the unit of healthcare coordination by accident — tax treatment and post-war wage controls, not any natural law. The monopoly depends on individuals remaining fragmented and unable to see or act on their collective position. A federated trust network dissolves that dependency one individual decision at a time. There is no minimum size, no required membership, no central body to capture. The network is whatever scale the individual trust decisions add up to, and it must respond to every one of them.

**Networks, not votes:** A support network in ACS is not formed by vote, not recognized by an employer, and not protected or constrained by labor law. It is built the same way a FOSS project is built — you start contributing wherever you are, others reference your work, and the network grows from there. Amazon warehouse workers and Starbucks baristas do not need to petition for union recognition or survive an NLRB election. They need to start a domain, contribute to it, and let others subscribe. The network is not tied to an employer and does not require the employer's acknowledgment to function. It is a reaction to a market disparity, not a legal structure. Laws and employers have no say in how people coordinate support for each other — they can only respond to what the network does, the same way incumbents can only respond to a FOSS fork by making their product better or becoming irrelevant.
