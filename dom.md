# DOM Taxonomy

## Overview

The document object model is a JSON-native schema for describing resources, their layout, and their content. Everything is a domain object addressable by key. The structure separates concerns into three layers: the resource descriptor (`rsrc`), the instance content (`me`), and the layout that maps between them.

---

## Top level

```
rsrc/     — resource descriptor. The template and metadata for a document type.
me/       — instance content. The actual sections, tables, and data for this document.
```

`rsrc` is the library — the shape of what a document of this type can contain. `me` is the instantiation — what this particular document actually contains.

---

## `rsrc` — Resource Descriptor

Defines the document type. Fields:

| Key | Meaning |
|---|---|
| `url` | Address of this resource. `_` is self-reference. |
| `lib` | Basis type this resource extends. `doc.report` is the base class. |
| `label` | Human-readable name. |
| `desc` | Short description. |
| `ico` | Icon. Can be an SVG expression. |
| `rec.0` | Record template — the schema for a single entry in this document type. |
| `catalog` | Filter, item, key, value — the query interface over the document's records. |

### `rec.0` — Record Template

A record is one entry in the document. It has four structural concerns:

**`env`** — how the system is set up to interact with this content. The head — context, environment, prerequisites.

**`content`** — the content itself.

**`io`** — how the content connects and participates with other things. The foot — appendix, references, CLI, external links.

**`table`** — tabular data associated with this record.

**`._`** — the typed sub-objects this record can contain. Named slots for specific domain objects:

```
section.name      — a document section
schedule.name0    — a schedule
gateway.name1     — a gateway definition
email             — an email record
budget            — a budget record
```

**`layout`** — how the record renders. Divided into:

- `head` — icon, url, table of contents
- `foot` — alerts, footnotes
- `scratch` — working space, not rendered
- `re` — current rendered state
- `im` — named section slots waiting to be instantiated. Maps position keys to section addresses:

```json
"im": {
    "0.namey": "sec.0",
    "1.namex": "sec.5"
}
```

The key is `position.name`, the value is the section address in `me`. This is the same `re`/`im` pattern as the filesystem layer — potential mapped to actual.

### `catalog`

The query interface over the document's contents:

| Key | Meaning |
|---|---|
| `filter` | Predicate over records |
| `item` | A single result item |
| `key` | Address/identifier of an item |
| `value` | Content of an item |

---

## `me` — Instance Content

The actual document. Sections addressed by key (`sec.0`, `sec.5`, etc.). Each section has:

| Key | Meaning |
|---|---|
| `label` | Section heading |
| `desc` | Subheading or description |
| `content` | Body text. Rendered under the heading according to the environment's rendering rules or output device. |
| `sec.N` | Nested subsections, same schema recursively |
| `table.N` | Tables belonging to this section |

### `table.N` — Table Schema

| Key | Meaning |
|---|---|
| `label` | Table heading |
| `desc` | Description |
| `column.N` | Column descriptor |

Each `column.N`:

| Key | Meaning |
|---|---|
| `label` | Column heading |
| `desc` | Description |
| `position` | Signed integer — column order, can be negative |
| `sort` | Sort definition: `order` (signed int) and optional `fn` for custom sort logic |
| `record` | String format descriptor for values in this column |

---

## Key conventions

**`_`** — self reference. The address of the current object.

**`_.`** — previous state (snapshot pointer, same as VCS layer).

**`._`** — next state or typed sub-object container depending on context.

**`#N`** — comment. Not rendered, not executed. Documentation inline with the data.

**`N.name`** — positional key. The integer prefix determines order, the name is the semantic label. Used in `im` to order section slots.

**`type.index`** — namespaced key. `sec.0`, `table.0`, `column.0` etc. Type is the schema class, index distinguishes instances.

---

## Rendering model

Content is environment-agnostic. `label` and `desc` become headings according to the output device's rules. `content` is rendered beneath them. The same document object can render to HTML, terminal, PDF, or any other target — the layout layer absorbs the difference.

The `im` layer in layout defines what *could* be shown. The `re` layer is what *is* shown. Instantiation is the mapping from `im` slots to actual `me` sections.

---

## The tree is the system

The namespace tree and the rendered state are two descriptions of the same data structure. Not a model and a view. Not source and output. The same thing, seen from two angles.

This is the Smalltalk insight applied to the whole system. In Smalltalk the live environment *is* the program — you don't edit source and compile and run, you reach into the running object graph and change it directly. The system and the representation of the system are one thing. ACS extends that to the full stack: filesystem, document, application, network — all of it is a live tree, and the interface is a tree editor.

What changes is what the tree is interpreted as:

| Tree context | Rendered state |
|---|---|
| Document | Page, report, handbook |
| Game engine | Scene, world state, entity graph |
| CAD environment | Geometry, constraints, assembly |
| CLI query | Remote service response, piped output |
| Filesystem | Directory listing, mounted volumes |
| Network | Federation graph, gateway routing table |

In every case the tree is live. Editing the tree changes the rendered state immediately. Observing the rendered state is reading the tree from a different angle. There is no compile step, no serialization boundary, no impedance mismatch between the data and the display.

This means the interface has one job: be a good tree editor that understands rendering context. The same editor that lets you reorganize a document section also lets you rewire a network gateway or modify a game entity — because those are all the same operation at the tree level. The rendering layer provides the appropriate affordances for the context, but the underlying operation is always the same: address a node, read or write its value, observe the propagated change.

The `im`/`re` distinction maps directly onto this. `im` is the tree as potential — the nodes that exist but aren't currently rendered. `re` is the tree as actuality — the nodes that are live and visible. Instantiation is promotion from `im` to `re`. The editor operates on both simultaneously.

Content-addressing ties it together: every state of the tree is a point in the address space. Every edit is a vector. The history of the system is a traversable graph of tree states, each addressable by hash. You can diff any two states, merge branches, or roll back — not as a special VCS operation but as ordinary navigation of the address space.

The live system is the tree. The tree is the system.

## Relationship to the rest of ACS

The DOM taxonomy is a domain in the ACS sense. A document type is a resource descriptor (`rsrc`) that can be instantiated (`me`) and addressed by hash. Version control over a document is the same VCS mechanism as any other domain — snapshot the `me` state, send stream between snapshots, address by hash. Federation means a document can be cached locally and synced against its canonical address. The same primitives all the way up.
