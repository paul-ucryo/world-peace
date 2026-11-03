# Domain Architecture

## Design Intent

Treat oppression and bigotry as dysfunction, then build a system that systematically targets dysfunction, not ideology. There is an implicit assumption that oppression and bigotry are inherently dysfunctional states. Evaluate the efficacy of that claim against everything that follows. The core problem this system addresses is coordination failure. As a proponent of free market, the framework assumes there is a net market pressure toward fairness and equality. Information theory can provide us the tools to resolve that pressure into noticeable incentives.

One critical aspect of the system, is to maintain focus and framing on behavior not identity. Focusing on heroes, leaves you leaderless when they aren't present. Focusing on adversarial identity gives them a narrative hold over your own problem space. It also changes the target. Focusing on identity you change people, focusing on behavior you change behavior. It doesn't matter if you change the behavior by changing people or by changing people, either way the behavior changed. Changing people only changes the behavior if the behavior isn't systemic. 

### The Mantra: See a Need, Fill a Need

We assume that system dysfunction produces friction in a system. That friction represents change potential. If we can map the change potential across system function, we can analyze problem spaces as market value. The idea is this gives a coherent market pressure toward just systems, it is not a license to optimize for market forces.

### Why the Current Layer Fails

If you only voice your opinion once every four years, the system will optimize out your communication channels. This is a behavior in any adaptive system. If you do not use an interaction surface, it is removed. Class structures create a statistical drift around who tends to use which channels. It is not useful to judge sides. The reason being, if we consider problems systemic and we aren't considering identity, then which side the systemic issue you are on is arbitrary. So again, we refocus on behavior, as that is what we want changed. And again, the dysfunction produces a net pressure toward every participants efficacy in their roles, which is a net pressure toward every participant performing better, being more agantic.

### The 9P Approach

Own your own problem space. As problems become more complex, it becomes more difficult to manage them. So we need to coordinate more efficient distribution of problem management. We start by clearly defining your own problem space. This is what you care about, what you are responsible for, what you own, the behavior you attribute to self. We are going to define a domain as a the set of behaviors attributed to that identity. Effectively, we are going to define a type system or encapsulation system over cryptographic identities. Meaning the data object store is ca store. By organizing the ca store into composable identity structures, we get a programmable type system for content addressing, data integrity, and data security.

So, ca's create a cryptographic type system over data. This embeds network transport semantics into the data type system. The ca is a domain, is a cryptographic identity is a type declaration, giving you a data integrity and security system via a cryptographic enforced capability type system. This is the cache storage object of network packet, you just pipe the data directly into a transport header, and its end to end encrypted, with a programmable sharing logic.

Thus, 9p's mounting system becomes a programmable network distribution system over the file system ns. Consider using tar as a header:body structure. So you have tar translators give you a single file handle with public/private sections or generally each tar'd file is a separate ownership rule. So unmounted volumes, (btrfs send and luks volumes) are wrapped in a ca cert via tar. The volume and its mount instructions and authorization travel together.

If we consider this type system, then perhaps the catalog directory inside the domain is effectively the ns against the ca tree. Its where instances of a type are instantiated. Meaning, perhaps, everything that refers to an instance of a type, is bound to the catalog directory, requires a valid catalog entry that matches the id of the data being declared. This makes the language entries in the catalog have clear meaning. The catalog is just ns so the system dictionary needs a graph between human language symbols and their meaning. By making the language system a catalog entry, you can search your system for relational meaning in any language simultaneously because the logic isn't based on words or name id's but dependency relations.

### The PID Loop

If we are considering dysfunction as the problem, then the workflow becomes a control problem over system consistency. The domain publishes a .policy file, indicating how the domain handles requests. So a community domain of any group size may declare, "stable health is identity invariant", "education is identity invariant". Now the audit system will track state against that policy. Basically, does the system respond to requests consistantly with those policies? This is not a judgment call. The system's audit reports would need to have a health metric and education metric, but if you have those metrics, you can test them against identity invariance. This does not mean that every node has the same path to health or education, or even equal health or education. What it does do, is say that if the system is not producing behavior that satisfies the the policy rule, it flags an error. That error becomes a domain, a project around which coordination of resources is directed. In particular, the self-consistency check should give you trace log. If the policy is not being met, where is the missing dependency. Rigorous attention to resolving missing dependencies should almost automatically produce actionable pressure toward resolving the policy conflict, without needing to understand the issues in their entirety before beginning to make progress. The analysis and the work of solving the problem aren't just parallel efforts, they are the same effort with differentiated output.

Think of the runtime workflow as a bind. You have the live system with inert molecules scattered in your fs. Then like dna, you bind a behavior to a site, it expresses a response and you then unbinds. This makes every operation a closure with side effects, and the fs is orchestration of side effects. And this pattern is universal across interactions with the system. Programs, files, transport, its a universal automation primitive. Its literally the specification of a rube goldberg machine made of digital particles. 

The monad structure gives a natural definition of complex value, the behavior vs the rendered state. This gives you a natural programming language that works across classical and quantum programming. Complex states are effectively just partial function, a mix of stable and unrendered state, where superposition is non deterministic (determinate = 0 of the transform). It doesn't matter if that effect is partial function or particles in superposition, informationally the space is not solved and quantum circuits are "just" superconducting partial functions (maybe constructable from superconducting rf 77 vs 20mK?). This also means the acs should include quantum encryption. Basically a specification for interfermetric proof isolation (how much sampling does your correlator need before it resolves what should be hidden structure and the security model is to isolate the data below that point). The cool thing is, this builds quantum proof isolation into free linux systems that can run on iot devices, home routers, phones. It also makes a quantum and classical programming the same language, so in a distributed system, the program uses whatever backend hardware is available/required. This also means mfa is the paradigm for quantum security, the data must only exist together in 1 place at the decryption surfaces.

---

## Directory Structure

ATM I'm calling it "ns". I see it as basically "vi" for structured data, a namespace editing environment. Another view would be a haskell inspired shell.

```
:$ ns {domain}
```
Would bind {domain} namespace to whatever the shell environment cursor indicates. 

```
:$ ns {domain0} {domain1} /
```
Would bind namespace {domain0} to the default site and then {domain1} to the same site (a join) and then the "/" or cut operator, which would unbind the join from the system env. Probably structured after haskell runtime. The type system definitions as just functions that define classes as well as the function application. So ns {domain0} {domain1} / is just function application. The type system implements pattern match and guards so you can use partial function application to generate guarded functions as a way to specify valid function ranges and then pattern match operations against guard conditions. So your programing the topology of action conditions. The type system is the catalog of things that need distinct behavior definitions with object definition being "all data that can be reliably bound to this context".

```
{domain}/
    .acs/           # Identity relational graph. Session monad.
    .hb/            # Handbook. Log, notes, comments, documentation.
        {session_id}.hb
    .pulse/         # Connector layer between runtime and .policy.
                    # Defines how the system responds to any given input.
                    # Fuzzy search between input state and .pulse structure
                    # produces compositional automation. The neural network
                    # transform over the domain.
        @{event}.sh     # Async tick/scheduler. Processes events against current state.
        _.sh            # Render loop handle. Advances rendered state. while _.sh()
        policy.sh
    .vcs/    #VCS is basically a clipboard/buffer catalog
        _/          # Local working frame. Session-specific history.
            {date}/ # Dated snapshots of in-progress work.
        public/     # Promoted, stable, externally addressable state.
            {name}.rpo  # Named stable modules. Mounted read-only into live system.
    audit/          # QC. Reports for reviewing system integrity.
    catalog/        # Namespace catalog. Relational graph of objects and their relationships.
        bcp47/      # Tokenized language dictionary.
        ledger/    #Catalog of deliverable goods/services. Things that can be exchanged/"legered"
    design/
        31d(cad).cat/        # 3+1D spatial geometry. The thing you want. This folder has a type where objects in 31d are subclass of catalog
        i(cam).cat/          # Imaginary axis. The set of operations that produce 31d/. Same subclassing as 31d.
        schema/          # svg or similar. Wiring schematics, database schema, symulink programs, ..
        src/
            index.html      # Public facing interface. Domain publication surface. publishes to gw.
            session.html    # User portal. Domain as tool. publishes to gw.
    inventory.jkk/      # Instantiated stock. Specific quantities of specific variants.
    budget/         # Transaction records.
        tax/
        .policy
    media/
        img/    #images and video
        src/    #live data. ch is probably a better name, but i think src is more clear semantically during development then ch.
            home/front_porch.cctv
            laptop/speaker1
            app4/
    share/          # Where public puts data.
        {session_id}/    #sort of like read/write io but more based on ownership then read/write direction.
    .policy         # Monad definition. All contents run against on write.
```

## .policy

Governs write behavior across the domain. Defines identity contexts.

    {
        "import": ["nda0", "gpl3"],
        "_": "nda0",
        "pub": "gpl3",
        "": ""
    }

- `_` — private context handle (nda0: cryptographic sealing)
- `pub` — published context, signed/asserted (gpl3: copyleft enforcement)
- `""` — default behavior is anonymity

## .acs/ Identity Contexts

    // .acs/nda0
    {
        "label": "nda0",
        "name": "NDA-0",
        "dscr": "Cryptographic enforcement of sealed content",
        "${label}": "{sha256(fs.nda0)}",
        "seal": ["fs:{pubkey}", "fs:{privkey}", "fs:{symkey}"],
        "": "${signature}"
    }

    // .acs/gpl3
    {
        "label": "gpl3",
        "name": "GPL-3.0",
        "dscr": "Cryptographic enforcement of copyleft as defined by GPL-3.0",
        "${label}": "{sha256(fs.gpl3.0)}",
        "seal": ["fs:{pubkey}", "fs:{privkey}", "fs:{symkey}"],
        "": "${signature}"
    }

## .vcs/ Version Composition

VCS states are composable units, not just history snapshots.

- `_/` — local working frame. Accumulates freely, not yet promoted.
- `public/` — stable coordination layer. Published modules others can mount.

Key principle: snapshots store composition relationships, not rendered output.

    vcs3 = diff vcs1 vcs2 | sidebyside

Rendered state is computed by .pulse when needed, not stored. This means:
- Compositions are themselves composable.
- Work done at the wrong level of abstraction is not lost, just not promoted.
- Rebase does not require unpicking rendered state — recompose against a different base.

## Workflow

### Snapshotting Work

In-progress work snapshots into `.vcs/_/{date}/`. These are working frame captures — not stable, not published, just preserved. The date-keyed structure means you can return to any point in the working history without it interfering with stable modules.

    # snapshot current state
    cat happy | birthday -> writes to .vcs/_/{date}/

Work at the wrong level of abstraction stays in `_/`. It isn't lost. It isn't promoted. When the framing becomes clearer, useful pieces can be composed into a stable module without having to reconstruct them.

### Promoting Stable Modules

When a piece of work is coherent enough to coordinate across contexts it gets promoted to `.vcs/public/{name}.rpo`. The `.rpo` is a named stable module — a discrete composable unit that other sessions and projects can mount.

The decision to promote is a judgment call: is this stable enough that someone else pulling from it won't be working against a moving target?

    # promote to stable
    vcs/_/{date}/some-work -> vcs/public/{name}.rpo

### Mounting the System Library

The system library is just `.vcs/public/` mounted read-only into the live system. No special library infrastructure — the stable modules are files in the repo pool, and mounting them read-only means the live system can use them without being able to corrupt them.

    mount -r .vcs/public/{name}.rpo -> live system namespace

Different projects mount different subsets of the repo pool. The namespace composition is what defines what a given session has access to.

### Composing Across States

Composition happens at view time via .policy, not at storage time.

    diff vcs0 vcs1 | sidebyside

This produces a composed view — not a merge, not a conflict resolution, just both states visible simultaneously. The user decides what to carry forward. Pieces worth keeping get promoted into the working frame or directly into a stable module.

The live system isn't a single rendered state. It's a view over the composition of mounted modules and the current working frame, processed through .pulse on each tick.

## Initialization

    init -> mount volume -> cat happy | birthday
                         -> cat {session} | birthday  # resume existing session

`cat happy | birthday` reinitializes context, reconnects persistent data,
snaps current state into .vcs.

## Repo Pool

The stable coordination layer shared across sessions and projects.

# The Argument for the Assumption

The primitive force in the universe is love. 2 things that are 1 thing told from a mobius boundary. A black hole is this. The white hole of a black hole is the event horizon viewed as an exhaust. The universe is 2 people who are 1 person trying to balance the pull together and need to be distinct into a narrative, into a dance between them. And that drives our need to dance. And the dance is not separate from the music that produces it or the history that it came from. The dancers producing the universe that created them.

- Publish here when something is coherent enough to coordinate across contexts.
- Pull from here when starting new sessions or projects.
- Never pull from another session's `_/` unless resuming that session directly.
- Integrity of what gets published builds the web of trust over time.
