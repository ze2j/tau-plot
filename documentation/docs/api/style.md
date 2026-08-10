# TauStyle

!!! info ""
    **Inherits:** `Resource`  
    **Inherited By:** [`TauXYStyle`](xy_style.md), [`TauPaneStyle`](pane_style.md), [`TauBarStyle`](bar_style.md), [`TauScatterStyle`](scatter_style.md), [`TauLineStyle`](line_style.md), [`TauLineFill`](line_fill.md), [`TauLegendStyle`](legend_style.md), [`TauTooltipStyle`](tooltip_style.md), [`TauCrosshairStyle`](crosshair_style.md)

**Abstract class** for the style resources, holding the resolution rules every one of them follows.

## Description

A style resource carries the visual parameters of one part of the plot. A configuration object always holds a style, created with it. Assigning a different instance is supported, and several configuration objects can share one. [`TauLineFill`](line_fill.md) is the exception, owned by [`TauLineStyle`](line_style.md) rather than by a configuration object.

The plot watches the style resource it received and picks up every assignment, so mutating a property at runtime does not require calling [`TauPlot.queue_refresh()`](tau_plot.md#queue_refresh), unlike mutating the configuration object that owns it.

### Three-layer cascade

The plot never draws from the style resource it receives. It builds a resolved copy, applies three layers to that copy in order, and draws from the result:

1. **Built-in default**  
    The plot creates a fresh instance of the style, the resolved copy, with every property at its default value.

2. **Theme value**  
    The plot overwrites the properties the Godot theme names. A property the theme does not name keeps its default value.

3. **User override**  
    The plot updates the resolved style using only the properties overridden in the user-provided style.

In short:

- the last layer that provides a value wins
- the Godot theme is for a shared, persistent look, with optional per-series and per-pane targeting
- a style resource is for overriding from code

**Override detection**

A property counts as overridden as soon as it is assigned, whatever the value, so assigning a property to exactly its built-in default from code still wins over the theme. For array properties, only assigning a new array marks the property as overridden. Mutating the array already in place does not.

A property set from the inspector to exactly its built-in default is not written to the saved resource, so it reads as untouched on load and the theme wins. Assign it from code instead.

```gdscript
var style := TauXYStyle.new()

# 4 is also the built-in default. The assignment still marks the property,
# so the theme no longer writes it.
style.pane_gap_px = 4
```

### Cycles

Most style properties are scalars, holding one value for everything the style covers.

The rest are **cycles**: arrays holding one entry per series, read modulo their own size. Series `i` uses entry `i % size`, where `i` is the series index in the [`Dataset`](dataset.md). A shorter array repeats from the start and a longer one leaves its extra entries unused, so a cycle never has to be kept in sync with the dataset.

```gdscript
var style := TauXYStyle.new()

# Six series come out red, blue, green, red, blue, green.
style.series_colors = [Color.RED, Color.BLUE, Color.GREEN]
```

An empty cycle is neither an error nor a way to defer to the theme. It falls back for every series, and each property documents its own fallback.

### Theme keys

A style is plot-wide or pane-scoped by nature. [`TauXYStyle`](xy_style.md), [`TauLegendStyle`](legend_style.md), [`TauTooltipStyle`](tooltip_style.md), and [`TauCrosshairStyle`](crosshair_style.md) describe things the plot draws once, so the plot resolves one copy of each. [`TauPaneStyle`](pane_style.md), [`TauBarStyle`](bar_style.md), [`TauScatterStyle`](scatter_style.md), and [`TauLineStyle`](line_style.md) describe the contents of a pane, so the plot resolves one copy per pane. A theme can set one value for every pane, or set a different value for a single pane, which it names by its zero-based position in [`TauXYConfig.panes`](xy_config.md#panes).

Each style reads its keys from its own theme type variation, named on its page. A key sits in the Godot theme category matching its type: `colors`, `fonts`, `font_sizes`, `styleboxes`, `icons`, or `constants` for everything numeric.

The scope of a style shapes the name of its keys. A scalar on a plot-wide style is the property name and nothing else:

```gdscript
[resource]
TauCrosshair/base_type = &"Control"
TauCrosshair/constants/crosshair_thickness = 2

# Everywhere in the plot, the crosshair is 2 pixels thick.
```

Each theme type variation needs its own `base_type` line, once, before its keys.

A scalar on a pane-scoped style accepts a pane index:

```gdscript
TauBar/base_type = &"Control"
TauBar/constants/bar_width_px = 12
TauBar/constants/bar_width_px_1 = 20

# In a plot with three panes:
#   pane 0: bars 12 pixels wide
#   pane 1: bars 20 pixels wide
#   pane 2: bars 12 pixels wide
```

A cycle is an array, and a theme entry can only hold one value, so a cycle is written one key per entry. On a plot-wide style the number is the entry index:

```gdscript
TauPlot/base_type = &"PanelContainer"
TauPlot/colors/series_color_0 = Color(1, 0, 0, 1)
TauPlot/colors/series_color_1 = Color(0, 0, 1, 1)

# In a plot with three series:
#   series 0: red
#   series 1: blue
#   series 2: red
```

The built-in palette of eight colors is gone. A run of cycle keys replaces the built-in cycle rather than writing over its first entries.

On a pane-scoped style the entry index comes first and the pane index second:

```gdscript
TauLine/base_type = &"Control"
TauLine/constants/line_width_px_0 = 2
TauLine/constants/line_width_px_1 = 4
TauLine/constants/line_width_px_1_2 = 6

# In a plot with four panes:
#   pane 0: series 0 is 2 pixels, series 1 is 4 pixels
#   pane 1: series 0 is 2 pixels, series 1 is 4 pixels
#   pane 2: series 0 is 2 pixels, series 1 is 6 pixels
#   pane 3: series 0 is 2 pixels, series 1 is 4 pixels
```

A pane key changes only the entry it names.

A cycle key always carries an entry index. There is no key without one.

The same trailing number therefore means different things depending on the property it belongs to. `bar_width_px_1` names a pane, `line_width_px_1` names a cycle entry.

### Merging instead of replacing

An overridden property replaces its value as a whole. Assign [`line_widths_px`](line_style.md#line_widths_px) and every width the theme set is gone.

That rule works badly for [`TauLineStyle.fills`](line_style.md#fills), whose entries are [`TauLineFill`](line_fill.md) resources carrying a dozen fields each. Changing the opacity of a themed gradient would mean restating the fill mode, the texture, the stretch span, and everything else the theme had already set.

A [`TauLineFill`](line_fill.md) is therefore a style resource itself, marking its own fields as they are assigned. The plot merges it field by field instead of replacing it: an assigned field wins, an unassigned one keeps what the theme gave it.

```gdscript
var line_style := TauLineStyle.new()

# Only the opacity changes. The themed fill mode and texture survive.
var faded := TauLineFill.new()
faded.alpha = 0.2
line_style.fills = [faded]
```

A `null` entry leaves its whole position to the theme, and an empty [`fills`](line_style.md#fills) leaves the themed cycle untouched.

### Notes

1. **Cycle indices must be contiguous from `0`.** The theme is read index by index and stops at the first one it does not define, so `series_color_0` and `series_color_2` without `series_color_1` yield a cycle of one color.

2. **Fractions are themed as percentages.** A Godot theme constant holds an integer, so a property whose value is a fraction carries `_percent` in its key name and resolves as the constant divided by `100`. A float that reads as a whole number, such as a width in pixels or an angle in degrees, keeps a plain integer key.

3. **`null` and the empty array are values.** Assigning either marks the property like any other assignment and suppresses the theme. Each property states what its resolved value becomes.

4. **Resource-typed properties must be reassigned rather than mutated.** A `Font`, a `StyleBox`, or a `Texture2D` changed in place is not detected, and the plot keeps the previous resolution. Assign a new instance instead.

## Related Classes

* [`TauXYStyle`](xy_style.md) Concrete subclass for the axes, the plot padding, and the series palette. Plot-wide.
* [`TauPaneStyle`](pane_style.md) Concrete subclass for the background and border of one pane.
* [`TauBarStyle`](bar_style.md) Concrete subclass for bar overlays.
* [`TauScatterStyle`](scatter_style.md) Concrete subclass for scatter overlays.
* [`TauLineStyle`](line_style.md) Concrete subclass for line overlays. Holds the [`TauLineFill`](line_fill.md) cycle.
* [`TauLineFill`](line_fill.md) Concrete subclass describing the filled area of one series. Themed through [`TauLineStyle`](line_style.md).
* [`TauLegendStyle`](legend_style.md) Concrete subclass for the legend. Plot-wide.
* [`TauTooltipStyle`](tooltip_style.md) Concrete subclass for the hover tooltip. Plot-wide.
* [`TauCrosshairStyle`](crosshair_style.md) Concrete subclass for the hover crosshair. Plot-wide.
* [`TauPlot`](tau_plot.md) The plot node. Resolves the cascade and holds the Godot theme the second layer reads.
* [`TauXYConfig`](xy_config.md) Holds the pane list a pane index refers to.
* [`Dataset`](dataset.md) Holds the series a cycle index refers to.