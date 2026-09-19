# Federated Domain Coordination Framework

## Core Concept

A federation of sovereign domains that coordinate without a central authority. Each domain is defined by a cryptographic key — the key is not just an identifier but the mechanism that physically enforces the domain boundary. Data belongs to a domain by being signed or encrypted with that key.

The domain is a virtual address space that instantiates lazily on interaction. It exists fully the moment the key exists, even if empty.

## Domain Structure

```
/fed/{domain}/:{
    acs:{},        // access control — who can decide what
    gw:{},         // gateway — name/address resolver/router.
    catalog:{},    // composable behavior catalog — products, team assignments, problem catagorization
    inventory:{},  // current state — what's held
    txn:{},        // transactions — exchanges between domains, mostly orders and ticket tracking
    msg:{
        rqst:{},   // requests — generic request. resource request, or project scope (dilverable declaration)
        report:{}, // reports — alert, error, warning
    },
    resolver:{}, // requires, suggest, permits, provides, suppliments, denys ..?
    design:{},     // intent and structure
    phase:{},      // versioned state — previous and next
}
```

## Keys as Boundaries

A key is not a name — a UUID names but doesn't partition. A key partitions because it controls access physically. Without the key you cannot cross the boundary.

- **Signed** = domain asserting itself to the environment. Outward facing. The environment can verify without being inside.
- **Encrypted** = domain protecting itself from the environment. Inward facing. Exclusion enforced.

Signed is the domain acting on the world. Encrypted is the domain maintaining its boundary against the world.

## Phase

Phase is position in change — not before/after (which implies external order) but previous/next, which are internal to the thing itself. Each point has exactly one previous and one next. The domain has one causal chain.

Phase is modeled as a cursor. The cursor is the domain's current position in its own change history. Fundamental operations:

- **previous** — move cursor back one position
- **next** — move cursor forward one position
- **bind** — open handler; attach to a resource at the current cursor position, making it active and addressable
- **release** — close handler; detach from the resource, freeing the reference

Bind and release are the interaction boundary — the moment the domain touches something and the moment it lets go. Everything between bind and release is in scope. Everything outside is not.

Phase is the versioned symlink graph over the domain's block storage. It tracks the composition — which datasets at which snapshot versions the namespace points to — not the content itself. Content is opaque to phase. Phase is opaque to content.

## Address Space and Paging

The domain is an address space — a range of addressable locations. Pages are fixed-size blocks within that space, sized to the access pattern of what's stored (SQL wants small blocks, CAD wants large blocks). Different datasets with different page geometries are composed under a single namespace via symlinks. The user sees one coherent domain. The paging geometry is invisible.

A name resolves to a block address. The filesystem is the name resolver — analogous to DNS but for storage. The OS maintains the mapping from virtual addresses to physical locations.

Two distinct logs track change:
- **Namespace mutations** — name created, moved, deleted, repointed
- **Block mutations** — content changed at this address

## Coordination as Dependency Resolution

The federation is a distributed dependency resolver. Each resource has a capability map — per-domain reachability requirements. Each node has a connectivity profile — uptime and reachability characteristics per domain.

The scheduler matches capability maps against connectivity maps and finds placements that satisfy requirements at minimum cost.

**Cost function inputs:**
- Node connectivity frequency — how often is this node reachable to the nodes it interacts with
- Resource reachability requirement — how critical is it for domain Y to reach resource X when needed
- These form two planes, not two numbers — each resource has per-domain reachability criteria

When a node's expected uptime falls below a resource's reachability requirement for a given domain, the scheduler acts — replicating or migrating before the node goes dark.

## The Control Loop

Every interaction with the system flows through a control loop:

1. Interaction arrives
2. State updates — access count, location, time, size, who
3. Heuristics observe and measure
4. Cost function evaluates placement against requirements
5. Scheduler acts or doesn't

The heuristics are sensors feeding the cost function. The cost function is the strategy — stable. The schedule is the current output of applying the strategy to current observations. Tuning the system means tuning the cost function, not the heuristics.

## Sync as Reachability Maintenance

Syncing is not about keeping copies consistent. It's about maintaining address reachability. Data moves because an address needs to stay valid — not because the user asked to sync.

The scheduler's most important input is predicted disconnection. It acts before a node goes offline, preemptively placing data where it needs to be.

## Peace and Coordination

World peace isn't imposed, it's learned. Imposed coordination is just suppressed conflict. The federation embeds this: no central authority, no castle that outsources protection. The coordination layer must keep users as agents — not passengers. The system has to respect you as a decider. And you have act like one to maintain the relationship.

Systems are defined by a balance between self and env. The boundary is emergent and functional not intrinsic.

Platforms respond to your actions but adapt to markets, not to you. They don't recognize you as an agent — they recognize you as an environment variable. A system you own treats you as a principal. It has obligations to you, not just manages your interaction.
