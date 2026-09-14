# Cryptographic Namespace Architecture

## The Core Idea

Every user gets a cryptographic keypair. That keypair defines their **personal namespace** — an infinite address space they alone can write to. Coordination does not disappear, but it **reduces to key management** — a well-defined, asynchronous, and largely solved problem. No central registry, no allocated ranges, no admin to ask, no live agreement needed at the moment of writing.

When users collaborate, they each work in their own namespace naturally. There are no branches to create or merge — **every user is already their own branch by construction**.

Data signed with a private key is not hidden — it is **attributed**. The public key reveals who said what. The result is a distributed space where anyone can publish anything, and every claim is cryptographically tied to an identity. It works like voice in a crowd — you can hear everyone, but you choose who to listen to based on identity, not based on whether you're permitted to hear the content.

Secrecy is also available as a design channel. Encrypting to a specific key or a derived subkey creates a private channel within the same system — controlling not just who is speaking but who can hear. Derived keys let you create group channels, one-to-one channels, or tiered access, all within the same identity framework and without a separate access control system.

---

## The Shift in Framing

This is not primarily a privacy or secrecy system. It is an **epistemic infrastructure** — a way to reason over truth across multiple sources without trusting any single one.

| Traditional System | This System |
|---|---|
| Single authoritative source | Many attributed sources |
| Trust the database | Verify the signature |
| Access control restricts who sees data | Signatures reveal who said what |
| Branches are created and managed | Every user is already a branch |
| Truth is what the system says | Truth is what you reason from evidence |
| Coordination is ongoing and broad | Coordination reduces to key management |

---

## How It Works

### Each User Gets a Namespace

A keypair defines an infinite, non-overlapping address space. Users generate identifiers independently — no race conditions, no central counter, no live coordination at write time. Two users can never collide because different keys produce different namespaces by construction.

```
User A keypair → namespace A (infinite)
User B keypair → namespace B (infinite)
User C keypair → namespace C (infinite)
```

Coordination still exists, but it reduces entirely to **key management** — establishing, distributing, and trusting public keys. That problem is well-understood, asynchronous, and does not require parties to be online or in agreement at the moment a record is created. No user needs to know how many others exist or where their range starts.

### Signing is Publishing, Not Hiding

When a user signs a record with their private key:

- The record is **attributed** to them verifiably
- Anyone with the public key can confirm who authored it
- The data itself is visible — the signature is provenance, not encryption
- No central authority needed to validate "who said this"

The signature **is** the authorship claim. It is embedded in the record itself, not stored in a separate audit log somewhere.

### Collaboration Without Branches

In a traditional system, collaboration requires creating a branch, managing merge conflicts, and reconciling state. Here:

- Each user works in their own namespace
- Their work is already isolated and attributed by identity
- "Merging" is just reasoning over multiple signed records
- There is no branch to create, name, manage, or delete

Two engineers working on the same assembly each produce records in their own namespace. Those records coexist in the shared space, each verifiably attributed. A downstream system — or a person — reasons over both.

---

## The Distributed Vault

The shared space functions as a **distributed vault**:

- Anyone can post anything
- Every post is signed — authorship is verifiable
- Nothing is hidden by default
- Restriction is not enforced by the system — it emerges from **trust and consensus**

There is no single gatekeeper deciding what is true or who can write. Instead, readers apply their own trust model:

- Do I trust this key?
- Does this record agree with others I trust?
- Is there consensus across multiple independent sources?
- Where do records conflict, and whose do I weight more?

**Truth is not declared by the system. It is reasoned over by the reader.**

---

## Epistemic Sovereignty

Each participant can:

- Publish claims into the shared space independently
- Attribute those claims verifiably to themselves
- Read all other claims without a gatekeeper filtering them
- Apply their own reasoning to determine what they believe

This is structurally different from systems where a central authority controls what is visible, what is canonical, or what is true. In this architecture, the authority to reason over truth belongs to the reader, not the infrastructure.

The system does not tell you what to believe. It gives you verifiable, attributed information and lets you decide.

---

## Information Channels from a Single Dataset

Because records are signed by identity, the same shared dataset naturally contains **multiple information channels**:

- Everything signed by Key A = A's channel
- Everything signed by Key B = B's channel  
- Records where A and B agree = consensus channel
- Records where they disagree = conflict channel, visible and reasoned over

You don't need separate databases for separate sources. You don't need to choose one authoritative source up front. The channels emerge from the signatures already present in the data.

---

## Trust and Consensus Boundaries

Restriction in this system is not enforced by access control. It emerges from trust:

- **Who do you choose to read?** — you subscribe to keys you trust
- **What constitutes consensus?** — you define your own threshold
- **How do you handle conflict?** — you apply your own reasoning
- **Who can you block?** — you ignore keys you don't trust

The system enforces nothing about truth. It only enforces **attribution** — that every claim is tied to an identity, and that identity cannot be forged.

This is the boundary: not "you cannot post this" but "whatever you post is signed as yours."

---

## Relationship to Existing Systems

| System | What It Shares |
|---|---|
| Tor v3 .onion | Public key *is* the address — no central DNS |
| Nostr protocol | Signed notes, identity-based, no central server |
| Secure Scuttlebutt | Identity-keyed append-only feeds, gossip distribution |
| Git | Content-addressed objects, but with central branch coordination |
| PGP Web of Trust | Key-based identity, but trust is explicit and manual |
| ActivityPub / Fediverse | Distributed publishing, but still server-mediated |

The key difference from most of these: **the emphasis is on reasoning over multiple attributed sources**, not on routing, messaging, or replication. The infrastructure is epistemic first.

---

## Properties

- **Coordination reduces to key management** — well-defined, asynchronous, largely solved
- **No central registry** — the math guarantees uniqueness
- **Attribution without secrecy** — signing reveals, not hides
- **Collaboration without branching** — identity *is* the branch
- **Anyone can publish** — restriction is social, not technical
- **Truth is reasoned, not declared** — the reader holds epistemic authority
- **Multiple channels from one dataset** — emerge from signatures, not schema
- **Runs on untrusted infrastructure** — no gatekeeper needed

---

## Open Questions

- **Key loss** — orphaned namespace if private key is lost; recovery strategy needed
- **Key rotation** — how to migrate an identity without breaking existing attribution
- **Human readability** — cryptographic handles need an alias layer for operational use
- **Sybil resistance** — anyone can create infinite keys; trust models need to account for this
- **Consensus mechanisms** — how do downstream systems formalize "enough signatures agree"
- **Revocation** — how to signal that a prior signed claim is retracted
