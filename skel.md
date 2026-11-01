# Domain Architecture

## Design Intent

The core problem this system addresses is coordination failure. Most global dysfunction — economic, political, social — traces back to a broken coordination layer: systems that don't route needs to resources, that absorb agency rather than distributing it, that optimize for engagement over resolution.

The root cause isn't bad actors. It's entropy. Systems atrophy when they don't exercise critical functions. The current metaverse — the unconscious coordination layer of connected infrastructure — doesn't exercise need-routing, so it reorganizes around what it has: attention. Extractive platforms are the result, not the cause.

The fix is engineering. Build a coordination layer that actually routes needs to resources, preserves prediction capacity at the edges, and measures integrity against reality rather than consensus.

### The Mantra: See a Need, Fill a Need

System dysfunction is the gap between need and response — tautologically. The architecture exists to close that gap.

### Why the Current Layer Fails

People raise issues where they feel they get a response, currently social media. But the response there is more communication, not action. The communication surface and the action surface have decoupled. Governance loses signal about real needs; action responds to bureaucratic maintenance and if that is poorly tied to request resolution then the system is unable to provide coherent, self consistent responses.

### The 9P Approach

The coordination layer is modeled on Plan 9's protocol: mountable namespace structures. A microkernel for distributed systems.

Key properties:
- No single actor owns the namespace
- Resources and needs are expressed as mountable structures
- Views are composable — different actors construct their own views of a problem space
- The coordination surface emerges where views overlap, not from top-down agreement

This is data windowing. The shared reality of a problem is wherever independent views intersect. You don't need consensus on the frame before routing resources toward a need — just overlap.

### PID Control Over Data Integrity

The system uses PID control with data integrity as the setpoint.

**The error signal**: Did the model accurately predict outcome? The delta between predicted and actual outcome is the error. This grounds the system in reality rather than consensus — neither party controls the reference.

**Why this works for coordination**: An adversarial node isn't an enemy in the traditional sense. It's a threat to data integrity. Your only job in evaluating a node is maintaining your own internal coherence. As that migrates out to the environment you interact with, it becomes a measure of how much integrity your environment maintains.

**The setpoint**: System response to need, distributed equally regardless of who holds the need. If the system responds unequally based on who holds a need, that's a detectable error — not a values judgment, a measurable asymmetry. The PID corrects toward equal responsiveness, not equal outcomes.

### Measuring Agency in Social Systems

**Needs are owned by the person who has them.** This is the foundational claim. You can't delegate a personal need because you possess it — it originates in your situation, your body, your life. A monopoly cannot make decisions over a need it doesn't own. Ownership of the need determines who holds the relevant information, and the balance of resolving that need is defined by who possesses the information required to resolve it.

A system that accurately addresses needs without creating local dysfunction necessarily delegates decisions to the target node — because the target node owns the need and therefore owns the information the decision depends on. Neither entity owns the problem space outright. Reality dictates which entity produces the decisions that resolve the need, based on who holds the relevant information.

**Monopoly defined precisely**: A monopoly is the possession of decisions that degrades your capacity to model your own outcomes unilaterally. Not market share as a proxy — market share is the possession of decisions. That's what it means.

The harm of monopoly isn't that it controls prices. A monopoly produces accurate predictions about its own domain — it controls the variables so it can afford to. The harm is that it degrades *your* prediction capacity. Not your ability to predict price or shipping. Your ability to predict: if I go to college will I get a job. If I work for this company will I be able to pay my expenses.

Variables that matter to your life become functions of the monopoly's behavior. Those decisions aren't modeled by anything you have access to. Your prediction capacity atrophies not because you got worse at modeling but because the system you're trying to model became opaque and concentrated.

**When modeling is wrong** — as in monopolistic, authoritarian, and anarchistic systems — dysfunction grows. Most commonly it relocates further into whichever system didn't participate in the decision. The dysfunction doesn't disappear, it migrates to whoever was excluded from the decision that affected them.

**A functional system that doesn't erode prediction capacity isn't a monopoly** — because it delegates decisions back to the node that owns the need. Lending capacity while retaining ownership is still concentration. Possession of ownership of decisions degrades your ability to operate within that space unilaterally.

**The integrity metric applied to social systems**: Does interacting with this node preserve or degrade my capacity to model my own situation? A monopoly that gives accurate prices while making life outcomes unpredictable is degrading integrity in the more important sense.

**Why the coordination layer addresses this**: No single actor owns the namespace, so no single actor can corrupt the reference. Outcome data needs to be as distributed and unownable as the namespace itself — otherwise the feedback loop can be suppressed by whoever controls outcome reporting.

**Web of trust**: Emerges from demonstrated ability to maintain coherent data when working with others. Not asserted upfront, demonstrated through the integrity of what gets published to the stable layer over time.

---

## Directory Structure

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
    .vcs/
        _/          # Local working frame. Session-specific history.
            {date}/ # Dated snapshots of in-progress work.
        public/     # Promoted, stable, externally addressable state.
            {name}.rpo  # Named stable modules. Mounted read-only into live system.
    audit/          # QC. Reports for reviewing system integrity.
    catalog/        # Namespace catalog. Relational graph of objects and their relationships.
        bcp47/      # Tokenized language dictionary.
    design/
        31d/        # 3+1D spatial geometry. The thing you want.
        i/          # Imaginary axis. The set of operations that produce 31d/.
        cad.catalog/
        nc.catalog/
        schema.catalog/
        src/
            main.dmc
            index.html      # Public facing interface. Domain publication surface.
            session.html    # User portal. Domain as tool.
    inventory/      # Instantiated stock. Specific quantities of specific variants.
    budget/         # Transaction records.
        .policy
    media/
        img/
        src/
            home.cctv
            speaker1
    share/          # Where public puts data.
        {session_id}/
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

- Publish here when something is coherent enough to coordinate across contexts.
- Pull from here when starting new sessions or projects.
- Never pull from another session's `_/` unless resuming that session directly.
- Integrity of what gets published builds the web of trust over time.
