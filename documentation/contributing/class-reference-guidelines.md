# Class Reference Writing Guidelines

This document defines how to write class reference pages for TauPlot, a GDScript plotting library for Godot. It targets writers who produce API documentation, not end users.

## Before You Write

Do not start writing a class page until you understand the class in context. Read the source file, but also read the classes it depends on and the classes that consume it. Trace how the class is constructed, configured, and used in practice. If the class is a configuration object, find out which method accepts it, which validator checks it, and what the plot does with it. If the class is a data container, find out who writes to it and who reads from it. If the class carries visual properties, read `style.gd` and the renderer that resolves them.

The goal is to write documentation that gives the reader a mental model of the class, not a flat list of members. You cannot produce that mental model if you only read one file.

Before writing, answer these questions for yourself:

- What problem does this class solve for the user?
- What is the typical lifecycle: creation, configuration, handoff to the plot, mutation over time?
- What other classes does the user need to understand to use this one correctly?
- What are the design constraints that shaped the API (ring buffer semantics, immutable modes, shared vs per-series ownership, cycle indexing, override marking)?
- Which validator rejects which misconfiguration, and does it abort, warn, or skip silently?

If you cannot answer these, keep reading the source until you can.

### Sources of truth

The source file wins over every other source. Class doc comments in the source are usually accurate but are written for a different audience, so treat them as evidence, not as text to copy. When the source and an existing page disagree, the page is stale.

Check every default value, every valid range, and every enum value against the declaration itself, not against the doc comment above it. A `@export_range` annotation, a class doc comment, a validator, and a property setter can each state a different bound for the same property.

Two families enforce a bound in two different places, so the source to trust depends on the class:

- A configuration class is checked by a validator, and the validator holds the bound the user hits. Document that one.
- A style class carries no validator. Its property setter clamps the value into range as it is assigned, so the setter holds the bound the user hits whatever layer the value arrives by. Document that one.

Whichever family the class belongs to, report every disagreement between the bound documented on the page and the one any other declaration states. A disagreement is a defect in the source, and leaving it unreported leaves it in place.

A value the plot adjusts where it draws, such as a grid line hidden at zero thickness, is behavior rather than a range and is documented as behavior.

## Public API Inventory

Only classes and enums listed here appear in the documentation. Any class not on this list is an implementation detail and must not be mentioned on any page.

### Naming

Classes registered globally with `class_name` carry the `Tau` prefix and are referenced by that full name, for example `TauAxisConfig`. Classes exposed as constants on the `TauPlot` namespace carry no prefix and are referenced either bare in prose, as `SampleHit`, or qualified in code, as `TauPlot.SampleHit`.

The page file name follows the source file name, not the class name. `TauAxisConfig` lives in `axis_config.gd`, so its page is `axis_config.md`. The one exception is `TauPlot` itself, whose source is `plot.gd` and whose page is `tau_plot.md`.

### Globally registered classes

|Class|File|
|---|---|
|`TauPlot`|`tau_plot.md`|
|`TauXYConfig`|`xy_config.md`|
|`TauPaneConfig`|`pane_config.md`|
|`TauAxisConfig`|`axis_config.md`|
|`TauGridLineConfig`|`grid_line_config.md`|
|`TauXYSeriesBinding`|`xy_series_binding.md`|
|`TauPaneOverlayConfig`|`pane_overlay_config.md`|
|`TauBarConfig`|`bar_config.md`|
|`TauScatterConfig`|`scatter_config.md`|
|`TauLineConfig`|`line_config.md`|
|`TauHoverConfig`|`hover_config.md`|
|`TauLegendConfig`|`legend_config.md`|
|`TauStyle`|`style.md`|
|`TauXYStyle`|`xy_style.md`|
|`TauPaneStyle`|`pane_style.md`|
|`TauBarStyle`|`bar_style.md`|
|`TauScatterStyle`|`scatter_style.md`|
|`TauLineStyle`|`line_style.md`|
|`TauLineFill`|`line_fill.md`|
|`TauLegendStyle`|`legend_style.md`|
|`TauTooltipStyle`|`tooltip_style.md`|
|`TauCrosshairStyle`|`crosshair_style.md`|

### Classes in the `TauPlot` namespace

|Class|File|
|---|---|
|`Dataset`|`dataset.md`|
|`ColorBuffer`|`color_buffer.md`|
|`Float32Buffer`|`float32_buffer.md`|
|`Float64Buffer`|`float64_buffer.md`|
|`Int32Buffer`|`int32_buffer.md`|
|`StringBuffer`|`string_buffer.md`|
|`VisualAttributes`|`visual_attributes.md`|
|`BarVisualAttributes`|`bar_visual_attributes.md`|
|`ScatterVisualAttributes`|`scatter_visual_attributes.md`|
|`LineVisualAttributes`|`line_visual_attributes.md`|
|`VisualCallbacks`|`visual_callbacks.md`|
|`BarVisualCallbacks`|`bar_visual_callbacks.md`|
|`ScatterVisualCallbacks`|`scatter_visual_callbacks.md`|
|`LineVisualCallbacks`|`line_visual_callbacks.md`|
|`SampleHit`|`sample_hit.md`|
|`DatasetChange`|`dataset_change.md`|

`tau_plot.md` carries a `## TauPlot Namespace` section listing every entry in this table with a one-line description. Keep that list and this table in sync.

### Enums

There is no `global_enums.md`. Every enum is documented on the page of the class that owns it, under `## Enums`.

|Enum|Owner page|
|---|---|
|`AxisId`|`tau_plot.md`|
|`PaneOverlayType`|`tau_plot.md`|
|`StackedNormalization`|`tau_plot.md`|
|`StackedNegativePolicy`|`tau_plot.md`|
|every other enum|the class that declares it|

An enum used by more than one public class is documented once on `tau_plot.md` and exposed as a constant on the `TauPlot` namespace, so both consumers link to a single definition instead of duplicating a table. `StackedNormalization` and `StackedNegativePolicy` are shared by `TauBarConfig` and `TauLineConfig` and are documented this way.

### Reachability

Every type a reader receives is public and needs a page, including types they never construct themselves. A signal payload is the common case: `Dataset.changed` carries a `DatasetChange`, so `DatasetChange` is documented even though only the plot creates one.

A public type must also be reachable without a path-based `preload()`. Global registration or a `const` on the `TauPlot` namespace both qualify. A type that can only be reached by preloading a source file by path is not yet public, whatever its role, and the page cannot be written until that is fixed.

## Page Structure

Every class page uses the following section order. Omit a section only when the class has nothing to put in it. Never reorder sections.

|#|Section|Heading level|Purpose|
|---|---|---|---|
|1|Title|`#`|Class name.|
|2|Info admonition|`!!! info ""`|Inheritance, subclasses, namespace.|
|3|Summary|Plain paragraph|One sentence stating the class responsibility.|
|4|Description|`##`|Role, context, relationships, constraints, modes.|
|5|Example|`###`|Minimal realistic GDScript snippet.|
|6|Notes|`###`|Numbered edge cases and clarifications.|
|7|Enums|`##`, one `###` per enum|Table with `Value` and `Meaning` columns.|
|8|Signals|`##`, one `###` per signal|Signature in a code block, then prose.|
|9|Constructor|`##`, one `###` per constructor|Same format as a method entry.|
|10|Properties|`##`, one `###` per property|Semantic description with meaning, default, valid values, side effects.|
|11|Methods|`##`|Grouped by `###` subheadings, individual methods at `####`.|
|12|Related Classes|`##`|Bullet list of linked class names with one-line relationship description.|

### Style pages

A style page documents a `TauStyle` subclass and inserts three fixed subsections into the Description, after the opening prose and before the Example:

|Order|Heading|Content|
|---|---|---|
|1|`### Three-layer cascade`|Snippet [S1](#s1-three-layer-cascade), transcribed as is.|
|2|`### Theming`|Theme type variation, base type, a base type declaration snippet, the theme key table, and the indexing rules.|
|3|`### Side effects`|Either the visual-only statement, or the layout-affecting and visual-only lists.|

`Example` and `Notes` follow, in that order. A style page without an Example is acceptable, since the owning config page usually shows the assignment.

The Three-layer cascade section is fixed text, pinned as snippet [S1](#s1-three-layer-cascade). `style.md` owns what a style page used to duplicate: the key indexing scheme, the contiguity requirement, the pane index, the inspector caveat, and the field-by-field merge rule. A style page keeps its own theme key table and nothing more.

The Theming section is the only place where a theme key appears, and it is page-specific. It must state:

- the theme type variation name and its base type
- one table row per theme key, in two columns
- whether the style is plot-wide or pane-scoped, and therefore whether keys take a pane index
- for cycles, that keys always carry a series index, with a link to `style.md` for what that means

### Ring buffer pages

`ColorBuffer`, `Float32Buffer`, `Float64Buffer`, `Int32Buffer`, and `StringBuffer` are one page written five times with the element type swapped. Write them as a family:

- The same section order, the same method groups in the same order, the same sentence shapes.
- Differences limited to the class name, the element type, the packed array type, the constructor signature, and the Example.
- The out-of-range and empty-buffer contract is snippet [S3](#s3-buffer-error-path), with the returned constant substituted per element type.
- Any correction to one page is applied to all five in the same change.

Do not let the family harden a claim that is only true for one member.

### The API index page

`index.md` lists every page in the reference, grouped by role, with one line per entry: the linked class name, a colon, and a short phrase naming what it is for. Groups and their order: entry point, data classes, series binding, plot configuration, additional configuration, style resources, per-sample visual attributes, per-sample visual callbacks.

The index is part of the definition of done for any new class. A class with a page but no index entry is unreachable by browsing. Mark abstract classes as abstract in their entry.

## Writing Rules

These rules apply to every sentence on every page. They are organized into three groups: language, content, and prohibitions.

### Language

1. Use present tense and active voice.
2. Write short factual sentences. One idea per sentence.
3. Use a tone that is: neutral, technical, direct, compact
4. Start descriptions with a verb when possible: `Returns`, `Sets`, `Appends`, `Emits`, `Logs`.
5. Use `If ..., then ...` for conditional behavior.

### Content

6. Describe observable behavior, not implementation details. The user should never need to read the source.
7. State what changes, what the constraints are, and what happens on invalid input.
8. Document side effects explicitly: signal emission, redraw, layout recomputation, cache invalidation, mode switches.
9. Document defaults and initial state. Do not assume users will guess them.
10. Specify units, coordinate spaces, valid ranges, and return values for edge cases (empty buffer, unknown ID, out-of-range index).
11. When a method or property is only valid in a specific mode, say so: `Only valid in SHARED_X mode.`
12. When a value is clamped, say so and say when: `Values below 1 are clamped to 1 on assignment.`
13. When invalid input logs an error, say so: `Logs an error if the ID is unknown.`
14. Distinguish the three failure modes. `plot_xy()` aborts on a validation error and leaves the previous plot untouched, pushes a warning and continues for a recoverable value, or silently ignores a setting whose preconditions are unmet. A silent skip is the one users cannot diagnose, so name it whenever it exists.
15. When a value is read in units that depend on another property, name the property. A marker size entry is in pixels or in X data units depending on the active size policy, and stating only one of the two is a defect.
16. When a property or parameter is an index, name the space it indexes. Dataset series index, overlay-local series index, logical sample index, pane index, and cycle index are five different things.
17. When a property holds a resource that must be reassigned rather than mutated in place, say so. An in-place change to a `Font`, a `StyleBox`, or an array is not detected by change tracking.
18. State the empty-collection behavior of every array property. An empty cycle falls back to a named constant, and that constant is part of the contract.

### Prohibitions

19. No em dash.
20. No semicolon.
21. No "you" or "your".
22. No marketing adjectives: "powerful", "easy", "convenient", "handy", "flexible".
23. No filler words: "simply", "just", "basically", "note that", "please note".
24. No passive constructions like "is designed to", "can be used to", "allows you to".
25. No repetition beyond the boilerplate blocks defined below. Do not restate the summary in the description. Do not re-list properties in prose. Do not explain the same constraint in two places.
26. No tutorials. A class page is reference, not a guide. Put extended walkthroughs in a separate guide and link to it.
27. No mention of internal classes. If a class is not in the Public API Inventory above, it does not exist for the reader. Renderers, validators, hit testers, controllers, geometry caches, and state snapshots are internal.

## Section Rules

### Info admonition

Directly under the title, an empty-titled info admonition carries the class relationships. Include only the lines that apply, in this order, each ending with two spaces so they render on separate lines.

```md
!!! info ""
    **Inherits:** [`TauPaneOverlayConfig`](pane_overlay_config.md)  
    **Inherited By:** [`TauBarConfig`](bar_config.md), [`TauScatterConfig`](scatter_config.md), [`TauLineConfig`](line_config.md)  
    **Namespace:** [`TauPlot`](tau_plot.md)
```

Rules:

- `**Inherits:**` names the **direct** base class, never a grandparent. Every style class inherits `TauStyle`, not `Resource`. Link it when it is in the Public API Inventory, otherwise leave it as inline code, as with `Resource`, `RefCounted`, or `PanelContainer`.
- `**Inherited By:**` appears only on a base class, and lists every direct subclass.
- `**Namespace:**` appears only on classes reached through the `TauPlot` namespace, and tells the reader the type is written `TauPlot.ClassName` in code.

### Summary

One plain sentence after the admonition. No blockquote. It names the responsibility of the class and its primary conceptual role. The summary gives the reader enough context to know whether this is the class they are looking for, even if they have never seen it before.

Good:

> Holds all X and Y sample data for one or more named series and notifies the plot of every change.

> Ring buffer that stores `Color` values with a fixed capacity.

Weak:

> A class used for data.

The first example works because it tells you what the class holds, how it is organized, and what it does actively. The weak example tells you nothing.

For an abstract class, open the summary with a bold marker so the reader stops before trying to instantiate it:

```md
**Abstract class** for overlay configurations rendered inside a pane.
```

### Description

The description is the most important section on the page. It must give the reader a progressive understanding of the class, starting from the big picture and narrowing toward specifics.

**Structure the description as a funnel.** Open with the broadest context: what role this class plays in TauPlot and where it fits relative to the classes around it. Then introduce the main concepts the class embodies (modes, ownership, buffering strategy, cycles). Then cover the constraints, defaults, and lifecycle rules that govern day-to-day usage.

A practical ordering:

1. What the class represents and what role it plays in the library. Name the classes that create it or consume it.
2. The main concepts the user needs to grasp: modes, shared vs per-series ownership, ring buffer semantics, configuration vs runtime distinction, or whatever applies.
3. Detailed behavior of each concept: how modes differ, what happens when mutated, what signals are emitted and when.
4. Constraints and defaults: what is immutable after construction, what the initial state looks like, what the user must configure before the class is useful.
5. The lifecycle boilerplate that closes the section (see Boilerplate Blocks), or the three style subsections for a style page.

Do not jump straight into low-level details. A reader who lands on the page for the first time needs to understand the purpose and context before they can make sense of modes, constraints, and edge cases.

Use **bold** for key terms on first definition (for example, **series**, **logical indices**, **cycle**). After the first occurrence, use plain text or inline code.

When a class has a small set of alternatives (modes, policies, strategies), introduce them in the description as a short bullet list of linked enum values with one clause each, then leave the full behavior to the enum table. Do not write the same three sentences twice.

Do not turn the description into a second summary. Do not enumerate every property or method. Do not make it a tutorial.

### Example

One GDScript code block showing typical creation and typical usage. Keep it under 15 lines and to a single scenario.

Rules for examples:

- The snippet must parse and run against the current API. Every class name, member, and method call in an example is a claim, and a stale example is the most expensive kind of error on a page.
- Declare or receive every variable the snippet reads. A snippet that reads an undeclared `dataset` is acceptable only when the page has no way to build one, and never for a call on a class name, such as reading a property off `TauPlot` that does not exist.
- Comments explain intent, not just label variables.
- Use a `# ---` separator line when the example has distinct phases (setup, then streaming, then teardown).
- Do not include unrelated scene setup.
- Do not indent the block body. The code starts flush left.
- Do not repeat examples that belong in a guide.

### Notes

A numbered list under `### Notes` inside the Description section. Notes are for **specific edge cases, caveats, and clarifications** that do not fit naturally into the descriptive prose above. They are not the place to introduce concepts. Every concept the user needs must already be explained in the description paragraphs before the notes.

Format: number, bold lead phrase, then the specific rule or caveat.

```
1. **Mode and element type are immutable.** To use a different combination, create a new
`Dataset` and call `plot_xy()` again.
```

Good note content:

- A constraint that is easy to miss ("add_series() fails after samples exist in SHARED_X mode").
- An edge case ("Out-of-range access logs an error and returns early.").
- A clarification about index shifting when the ring buffer wraps.
- An append-never-rejects semantic.
- A property that merges with the theme instead of replacing it.

Bad note content:

- Explaining what a series is (belongs in the description).
- Explaining the difference between SHARED_X and PER_SERIES_X (belongs in the description).
- Restating the class purpose (belongs in the summary).

Number the notes so other parts of the page can cross-reference them, for example `see [note 1](#notes)`.

### Enums

One `###` subheading per enum, with the enum name in backticks. Follow it with one sentence stating what the enum controls, then a two-column table with `Value` and `Meaning` headers. Write the meaning as a short sentence, not a single word. Separate consecutive enum entries with `---`.

```
| Value | Meaning |
|---|---|
| `SHARED_X` | All series share one X buffer. Sample index `i` maps to the same X value for every series. |
| `PER_SERIES_X` | Each series owns independent X and Y buffers with its own sample count and X positions. |
```

List every declared value, including the ones that are not usable as data, and say why they are not. `COUNT` and `NONE` on `MarkerShape` are the model.

When an enum name collides with a property name on the same page, as `Type` does with `type`, give the enum heading an explicit anchor and link that anchor everywhere:

```md
### `Type` { #type-enum }
```

Without it both headings slugify to the same value and every link on the page resolves to whichever came first.

### Signals

One `###` subheading per signal, with the signal name and parentheses in backticks. Show the full signature in a code block, then describe when the signal is emitted and what the parameter carries.

When the parameter type is deliberately undocumented, say in one sentence that the plot consumes it and the handler can ignore it. Do not name a type the reader cannot look up without saying what to do with it.

### Constructor

One `###` subheading per constructor, including static convenience constructors like `make_shared_x_categorical()`. Use the same format as a method entry. State whether the result is ready to use and which members must still be assigned.

The constructor blurb must not restate a rule the Description already covers, and must never contradict it. On style pages the blurb states what a fresh instance holds and stops there. Do not append a sentence about theme overridability, which is the Description's job.

Abstract classes have no Constructor section.

### Properties

One `###` subheading per property, holding the bare property name so the anchor is `#property_name`. Under it, a signature line with the name in backticks and the type linked when it is a documented class or enum. Then the prose. Then `---` before the next property.

```md
### tick_count_preferred

`tick_count_preferred`: `int`

The preferred number of ticks on the axis. Default is `5`.

Only used when [`type`](#type) is [`CONTINUOUS`](#type-enum). The actual tick count may differ from
this preference. Values below `2` are treated as `2`, and `plot_xy()` pushes a warning when that
happens.

---
```

Order within an entry:

1. What the property means, in one sentence, ending with the default value.
2. When it applies and when it is ignored.
3. Valid range, units, empty-collection fallback, and what happens outside them.
4. Side effects, including whether a change triggers a redraw only or a full layout recomputation.

Only include the items that are relevant. If a property has no side effects, omit that line.

### Methods

Group methods into logical subsections using `###` subheadings. Use `####` for individual methods. Order groups by workflow: introspection first, then construction helpers, then mutation, then clearing. Within a group, order by frequency of use.

Typical group names from the library: `Plot lifecycle`, `Introspection`, `Series lifetime`, `Series order`, `Capacity`, `Sample counts`, `Appending samples`, `Reading and writing individual values`, `Batch updates`, `Clearing data`.

#### Method entry format

```
#### method_name()

\`\`\`gdscript
method_name(p_param: Type, p_other: Type) -> ReturnType
\`\`\`

Prose description of behavior.

**Parameters**

* `p_param: Type` Meaning, unit, range, or constraint.
* `p_other: Type` Meaning, unit, range, or constraint.
```

Rules for method entries:

- The heading contains only the method name with parentheses. No parameters in the heading.
- The code block contains the full signature with parameter names, types, and return type, copied from the source. The bullets under **Parameters** must match that signature exactly, one bullet per parameter, no more.
- The prose description is plain text below the code block, no subheading.
- `**Parameters**` is a bold heading, not `##` or `###`, followed by a bullet list.
- Each parameter bullet starts with the name and type in backticks, then a space, then the description.
- Use `**Notes**` bold headings for extra structured information after parameters.
- Place a `---` horizontal rule between method entries within the same group.

Rules for prose descriptions:

- Open with what the method does, not what it is.
- State the return value meaning, not just the return type.
- State what happens on invalid input: `Logs an error and returns 0 if the ID is unknown.`
- State signal emission: `Emits changed.`
- State mode restrictions: `Only valid in SHARED_X mode.`

### Related Classes

A bullet list. Each item links the class name and gives a one-line description of the relationship.

```
* [`Dataset`](dataset.md) The data model. Passed to `plot_xy()`.
* [`Float64Buffer`](float64_buffer.md) Sibling ring buffer storing `float` values (64-bit).
```

Use relationship phrases like: "Sibling", "Passed to", "Owned by", "Holds", "Maps a ... to a ...", "The ... node.", "Base class.", "Concrete subclass for ...".

Every class named anywhere in the page body appears in this list. When a page gains a new sibling, this list is the checklist that catches the omission. Check the link target as well as the name.

## Boilerplate Blocks

Several contracts hold for whole families of classes. Repeating them on every page is intentional, because a reader lands on one page and must not need a second one to learn that a mutation needs a refresh. The wording is fixed so the repetition stays searchable and a change to the contract is a single find and replace.

Do not paraphrase these. Do not invent a variant.

Four of them are pinned as copy-ready snippets in [Appendix. Verbatim Snippets](#appendix-verbatim-snippets). The entries below say what each contract is for and where it applies, the appendix holds the text to transcribe.

### Runtime mutation

On every configuration class consumed by `plot_xy()`:

> After `TauPlot.plot_xy()` succeeds, the plot holds a reference to this instance. Mutating a property at runtime is supported, but requires calling `TauPlot.queue_refresh()` to apply the change.

Use the plural form ("to every instance it received") on classes the plot receives several of. On a base class page, "instance" may be qualified with the class name ("to every `TauPaneOverlayConfig` instance it received") when the surrounding text names several classes.

### Style ownership

On every `style` property:

> Never `null`. Modify properties directly on the instance. Any property left unassigned on this instance can still be set by the active Godot theme. Multiple `<OwnerClass>` instances can share the same [`<StyleClass>`](<style_page>.md) resource.

### Three-layer cascade

The whole `### Three-layer cascade` section on every style page. Snippet [S1](#s1-three-layer-cascade).

The inspector caveat is not part of it. It applies to every style resource equally and lives on `style.md`.

Never write "left at its built-in default", "override detection limitation", or "properties left at their defaults remain theme-overridable". All three claim that a property is compared against its default value, when detection is assignment-based.

### Cycles

On every style property that is an array of per-series values. Snippet [S2](#s2-cycle-property).

State the fallback constant by name. Do not write "the built-in default" without saying what it is.

State the clamp where the setter bounds the entries, and drop that clause where it leaves them unbounded.

### Buffer error path

On every ring buffer read that takes a logical index, on all five buffer pages. Snippet [S3](#s3-buffer-error-path).

The returned constant is part of the contract, so it is named on the page rather than described as a default.

### Non-serializable member

As the last paragraph of the property entry, on every `Callable` or `VisualAttributes` member that is not exported:

> `<member>` is not serializable. The property is not exported and cannot be saved in a `.tres` resource file. Assign it at runtime only.

The member owns the constraint, so it is stated where a reader looking the member up will land. It is not a note and takes no bold lead phrase.

### Per-sample override resolution

Stated once, in full, on `TauPaneOverlayConfig`: the two per-sample mechanisms, and the order the plot reads them in, a buffer entry first, then a callback, then the property. Every other page links to it rather than restating the order. Snippet [S4](#s4-per-sample-override-resolution) holds both the full block and the pointer line.

## Formatting Conventions

### Markdown structure

- One file per class, named after the source file.
- Keep headings flat. The deepest level in normal use is `####` for individual methods.
- Use `---` horizontal rules between sibling entries inside Enums, Properties, and Methods. Do not use them to separate top-level sections.

### Inline code

Wrap every symbol reference in backticks: method names (`set_domain()`), property names (`line_width`), class names (`Dataset`), enum values (`SHARED_X`), parameter names (`p_capacity`), theme keys (`bar_width_px`), types (`PackedFloat64Array`), and literal values (`0.0`, `null`, `true`, `-1`), with links when relevant.

### Linking

Whenever an enum value, method, property, signal, or class name appears in prose or a parameter description, link it to its definition. This applies to every occurrence, including inside `**Parameters**` blocks.

Anchors follow MkDocs slugification of the heading text: lowercase, punctuation dropped, spaces to hyphens. A `#### plot_xy()` heading yields `#plot_xy`. A `### \`DomainPaddingMode``heading yields`#domainpaddingmode`.

Formats:

- Same-page property: ``[`tick_count_preferred`](#tick_count_preferred)``
- Same-page method: ``[`queue_refresh()`](#queue_refresh)``
- Same-page enum: ``[`DomainPaddingMode`](#domainpaddingmode)``
- Same-page enum value: ``[`FRACTION`](#domainpaddingmode)``, pointing at the table that defines it
- Same-page signal: ``[`sample_hovered`](#sample_hovered)``
- Same-page note: `[note 1](#notes)`
- Other class: ``[`Dataset`](dataset.md)``
- Other class member: ``[`TauPlot.plot_xy()`](tau_plot.md#plot_xy)``

Links inside code blocks are not possible. No special handling is needed there.

### Code blocks

- Language tag: `gdscript`.
- Constructor signatures include the class name: `Dataset.new(...)`.
- Instance method signatures omit the class name: `get_mode() -> Mode`.
- Callback signatures are shown as a bare `func(...) -> Type` line in their own block, followed by one bullet or sentence per parameter.
- Theme snippets use `gdscript` as well, showing the `[resource]` header, the base type declaration, and the keys.

### Tables

Use tables only for:

- enums, two columns: `Value`, `Meaning`
- theme keys, two columns: `Theme property`, `Description`, where the first cell holds the key name and its type as `` `bar_width_px`: `int` `` and the second says which property it maps to
- namespace and inventory listings

Do not use tables for property lists or method lists.

## Vocabulary

Use these terms consistently across all pages. Do not invent synonyms.

|Term|Meaning|
|---|---|
|plot|The `TauPlot` node that renders a plot. Avoid chart term.|
|series|A named sequence of X/Y samples inside a `Dataset`.|
|sample|One X/Y data point in a series.|
|dataset|The `Dataset` object holding all series and their samples.|
|axis|A horizontal or vertical scale mapping data values to screen positions.|
|domain|The data range visible on an axis.|
|pane|A rectangular area inside the plot that holds one or more overlays.|
|overlay|A visual layer in a pane (bar, scatter, or line).|
|marker|A shape drawn at each scatter sample position.|
|tick|A labeled graduation mark on an axis.|
|ring buffer|A fixed-capacity buffer that drops the oldest value when full.|
|capacity|The maximum number of values a ring buffer can hold.|
|logical index|Zero-based index where `0` is the oldest value and `size() - 1` is the newest.|
|data space|Coordinate system using data units (the values the user passed in).|
|screen space|Coordinate system using pixel positions on screen.|
|series ID|A stable integer assigned at series creation, valid across reordering and renaming.|
|label|Labels are string associated to ticks. Do not confound with titles.|
|title|Titles are string describing an element like the whole plot or an axis. Do not confound with labels.|
|cycle|A style array holding one entry per series, read as `series_index % size`.|
|override|A style property marked as user-set by assignment, which the theme no longer writes.|
|cascade|The three-layer resolution of a style property: built-in default, theme, override.|
|theme key|The name a `Theme` resource uses for one style property, optionally carrying a series or pane index.|
|theme type variation|The `Theme` type a style resource reads its keys from, such as `TauBar`.|
|visual attributes|Per-sample override buffers handed to the plot with the data, read by sample index.|
|visual callbacks|Per-sample override functions called at draw time, storing nothing.|
|stack|The set of samples at one X position accumulated by a stacking overlay.|
|normalization|The total each stack is scaled to.|
|hit|One sample reported by hover hit testing, described by a `SampleHit`.|
|gap|Empty space between two drawn elements, or a break in a line caused by an invalid sample.|

## Writer Checklist

Complete every item before considering a class page finished. If any item fails, the page needs more work.

Understanding:

- [ ] I have read the source file for this class and the source of every class it directly interacts with.
- [ ] I have read the validator that checks this class, and every error and warning it can produce appears on the page.

Structure:

- [ ] Section order matches the page structure table in this guideline, including the style page variant when it applies.
- [ ] The info admonition names the direct base class, not a grandparent, plus the subclass and namespace lines when they apply.
- [ ] The summary is one sentence and tells a new reader what the class is for and how it fits in TauPlot.
- [ ] The description opens with the big picture and narrows progressively toward specific behavior, constraints, and defaults.
- [ ] The description does not repeat the summary in different words.
- [ ] The notes contain only edge cases and clarifications. Every concept the reader needs is already introduced in the description prose above.
- [ ] Every boilerplate block that applies is present, with the exact wording from this guideline.
- [ ] Every snippet from the appendix is copied as is, with only its listed substitutions applied.
- [ ] The Constructor blurb adds no rule the Description already states, and contradicts none of them.
- [ ] The page has an entry in `index.md`.

Accuracy:

- [ ] Every default value on the page matches the declaration in the source, not the doc comment above it.
- [ ] On a configuration class, every valid range matches the validator, and any disagreement with `@export_range` or the doc comment is reported.
- [ ] On a style class, every valid range matches the bound its setter enforces and states that it applies on assignment, and any disagreement with `@export_range` or the doc comment is reported. A value adjusted where it is drawn is documented as behavior, not as a range.
- [ ] Every enum table lists every value declared in the source.
- [ ] Every unit is stated, including units that depend on another property.
- [ ] Every index names the space it indexes.
- [ ] Every array property states its empty-collection fallback by name.
- [ ] Every parameter bullet corresponds to a parameter in the signature above it, and none is missing.
- [ ] The example parses and runs against the current API, and declares every variable it reads.
- [ ] Every method entry documents behavior, not just the name.
- [ ] Every method entry states what happens on invalid input.
- [ ] Every side effect is documented, including whether a change triggers a redraw only or a layout recomputation.
- [ ] Silent skips are named as such.
- [ ] For a style page, every theme key in the table exists in `load_from_theme()`, and every key read there appears in the table.

Links and language:

- [ ] Every enum value, method, property, signal, and class name in prose is linked to its definition.
- [ ] No two headings on the page slugify to the same anchor.
- [ ] Every class named in the body appears in Related Classes, with the correct link target.
- [ ] No class or type mentioned on this page is absent from the Public API Inventory.
- [ ] No em dash, no semicolon, no "you", no filler, no marketing language anywhere on the page.
- [ ] Vocabulary matches the table in this guideline.
- [ ] A user who reads only this page can use the class correctly and predict its behavior without reading the source.

---

## Template

````md
# TauClassName

!!! info ""
    **Inherits:** [`BaseClass`](base_class.md)  
    **Inherited By:** [`SubClass`](sub_class.md)  
    **Namespace:** [`TauPlot`](tau_plot.md)

One-sentence summary of the class responsibility.

## Description

Describe the role of the class in TauPlot.

Explain:
- What the class represents or does
- The concepts it embodies (modes, ownership, cycles)
- How it relates to nearby classes
- Important usage constraints
- Important defaults or lifecycle rules

Close with the runtime mutation boilerplate when the plot consumes this class.

### Example

```gdscript
var object := TauClassName.new()

# Minimal realistic setup.
```

### Notes

1. **Lead phrase.** Specific edge case or clarification.

2. **Lead phrase.** Another edge case or clarification.

## Enums

### `EnumName`

Description of what this enum controls.

| Value | Meaning |
|---|---|
| `VALUE_A` | What this value means in practice. |
| `VALUE_B` | What this value means in practice. |

## Signals

### `signal_name()`

```gdscript
signal_name(p_param: Type)
```

When the signal is emitted and what the parameter carries.

## Constructor

### `new()`

```gdscript
TauClassName.new(p_param: Type) -> TauClassName
```

What the constructor produces and whether the result is ready to use.

**Parameters**

* `p_param: Type` Meaning, unit, range, or constraint.

## Properties

### property_name

`property_name`: [`Type`](#enumname)

Meaning of the property. Default is `value`.

When it applies, valid range, and side effects.

---

### other_property

`other_property`: `bool`

Meaning of the property. Default is `false`.

## Methods

### Group Name

#### method_name()

```gdscript
method_name(p_param: Type) -> ReturnType
```

Describe behavior here.

**Parameters**

* `p_param: Type` Meaning, unit, range, or constraint.

---

#### other_method()

```gdscript
other_method() -> void
```

Describe behavior here.

## Related Classes

* [`OtherClass`](other_class.md) Why it is related.
* [`AnotherClass`](another_class.md) How it differs or collaborates.
````

## Style Page Template

````md
# TauSomethingStyle

!!! info ""
    **Inherits:** [`TauStyle`](style.md)

Controls the visual appearance of <what>.

## Description

What the drawn thing is, then what this resource controls about it.

Where the instance lives, whether it is ever `null`, and whether several owners can share it.

Which properties are cycles, and what an empty cycle falls back to.

### Three-layer cascade

<snippet S1, transcribed as is>

### Theming

Theme type variation, base type, base type declaration snippet, theme key table, indexing rules.

### Side effects

Visual-only, or the layout-affecting and visual-only lists.

### Notes

1. **Lead phrase.** Edge case.

## Constructor

### `new()`

```gdscript
TauSomethingStyle.new() -> TauSomethingStyle
```

What a fresh instance holds.

## Properties

### property_name

`property_name`: `Type`

Meaning. Default is `value`.

Range, clamps, empty-cycle fallback, per-sample override pointer.

## Related Classes

* [`TauStyle`](style.md) Base class. Defines the cascade, cycles, and theme key naming.
* ...
````

---

## Appendix. Verbatim Snippets

Copy the snippet, then apply the substitutions listed under it.

### S1. Three-layer cascade

````md
### Three-layer cascade

Each property is resolved in three layers: the built-in default, then the value the active Godot theme names, then the value assigned on this instance. A property counts as overridden as soon as it is assigned, whatever the value, and for an array property only assigning a new array counts.

See [`TauStyle`](style.md#three-layer-cascade) for the cascade and [`TauStyle`](style.md#theme-keys) for the grammar of the keys listed in [Theming](#theming).
````

No substitution.

### S2. Cycle property

Closes the property entry of a style property that holds one entry per series, after the sentence stating what the property controls and its default.

````md
Read as a cycle: series `i` uses entry `i % size`, where `i` is the series index in the [`Dataset`](dataset.md). <CLAMP> as the array is stored. An empty array falls back to `<FALLBACK>` for every series. See [`TauStyle`](style.md#cycles).
````

* `<CLAMP>` The bound the setter enforces, worded as writing rule 12 words it, as ``Entries below `1.0` are raised to `1.0` `` or ``Entries outside `0.0` to `1.0` are clamped into that range``. The trailing `as the array is stored` already carries the when rule 12 asks for, so do not repeat it. Drop the sentence on a cycle the setter leaves unbounded, as [`TauXYStyle.series_colors`](xy_style.md#series_colors), [`TauScatterStyle.marker_shapes`](scatter_style.md#marker_shapes), and [`TauLineStyle.fills`](line_style.md#fills).
* `<FALLBACK>` The constant the source declares for the empty case, as `DEFAULT_SERIES_ALPHA` or `DEFAULT_MARKER_SIZE_PX`, or the literal where the source declares none, as `2.0` for [`TauLineStyle.line_widths_px`](line_style.md#line_widths_px). When the fallback is a sentinel meaning no change, state what it resolves to as well.

### S3. Buffer error path

Every read that takes a logical index, on the five ring buffer pages.

````md
Reading an empty buffer, or a logical index below `0` or at or above [`size()`](#size), pushes an error and returns `<FAILED_READ>`.
````

* `<FAILED_READ>` `NO_COLOR` on `color_buffer.md`, `0.0` on `float32_buffer.md` and `float64_buffer.md`, `-1` on `int32_buffer.md`, `""` on `string_buffer.md`. `dataset.md` uses `0.0` for [`get_series_y()`](dataset.md#get_series_y), which inherits this path.

### S4. Per-sample override resolution

The full block lands once, on `pane_overlay_config.md`, in the Description. Every other page uses the pointer line.

````md
### Per-sample overrides

Some properties can be overridden per sample, through one of two mechanisms.

**Visual attributes** are buffers handed to the plot with the data, holding the value of one property indexed by sample index. The values are normally precomputed, which is what the mechanism is for. Writing them at runtime works as well, and leaves the caller responsible for keeping them in step with the [`Dataset`](dataset.md). See [`TauXYSeriesBinding.visual_attributes`](xy_series_binding.md#visual_attributes).

**Visual callbacks** are functions handed to the plot, called once per sample while the pane is drawn, and returning the value of one property for that sample. Each one receives the series index, the sample index, and the X and Y values of the sample, so the value can be derived from the sample itself. See [`visual_callbacks`](#visual_callbacks).

The plot reads the buffer first. If the buffer holds no value for a sample, the plot calls the callback. If the callback returns no value either, the plot uses the property. A `null` buffer, a buffer shorter than the sample count, an invalid entry, an unassigned callback, and an invalid return all count as no value.
````

Pointer line, on every other page:

````md
This property can be overridden per sample. See [`TauPaneOverlayConfig`](pane_overlay_config.md#per-sample-overrides) for more information.
````

No substitution.