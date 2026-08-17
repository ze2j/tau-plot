# TauLineFill

!!! info ""
    **Inherits:** [`TauStyle`](style.md)

Controls the area painted around the curve of one series in a line overlay.

## Description

A line overlay draws one curve per series. `TauLineFill` describes the area painted around one of those curves.

Each series has its own fill. The fills are held in [`TauLineStyle.fills`](line_style.md#fills), which is [a cycle](style.md#cycles): the array holds one fill per series, and an overlay with more series than entries reuses the entries from the start. Two series in the same overlay can therefore be filled differently, or one can be filled and the other not. A series whose entry is `null`, or a series in an overlay whose [`fills`](line_style.md#fills) array is empty, gets a fill at the built-in defaults, which paints nothing.

### Which area is painted

[`fill_mode`](#fill_mode) selects the area:

- [`NONE`](#fillmode) paints nothing.
- [`TO_BASELINE`](#fillmode) paints the area between the curve and a flat level, set by [`fill_baseline`](#fill_baseline).
- [`STACKED`](#fillmode) paints the area between the curve and the curve of the series below it in the stack. The bottom curve is painted down to zero. This turns a stacked line overlay into a stacked area chart, and it requires [`TauLineConfig.mode`](line_config.md#mode) to be [`STACKED`](line_config.md#linemode).

A painted area therefore always runs between two edges: the curve of the series, and an **opposite edge**, which is the baseline for a [`TO_BASELINE`](#fillmode) fill and the curve below for a [`STACKED`](#fillmode) one.

### How the area is painted

The area is painted either with a flat color or with a texture, never with both. The paint is picked in this order:

1. If [`texture`](#texture) is not `null`, the area is painted with that texture, and [`color`](#color) is ignored.
2. Otherwise, if [`color`](#color) is not the sentinel [`NO_COLOR`](#color), the area is painted with that color.
3. Otherwise the area is painted with the color of the series, read from [`TauXYStyle.series_colors`](xy_style.md#series_colors). That color is resolved by its own [cascade](style.md#three-layer-cascade) on [`TauXYStyle`](xy_style.md).

Whichever of the three applies, the alpha of the result is then multiplied by [`alpha`](#alpha).

### How a texture is painted

[`texture_mode`](#texture_mode) picks one of two ways to paint a texture.

[`TILE`](#filltexturemode) repeats the texture at its native pixel size, for a motif such as dots or hatching. [`tile_scale`](#tile_scale), [`tile_rotation_deg`](#tile_rotation_deg), and [`tile_offset_px`](#tile_offset_px) control how the tiles are laid out.

[`STRETCH`](#filltexturemode) reads the texture as a color scale instead of an image. At every point of the painted area the plot measures one value, and that value picks the color of the point somewhere in the texture. What is measured is set by [`stretch_span`](#stretch_span).

Each span measures a different quantity and reads the texture along a different axis:

- [`LINE`](#fillstretchspan) measures where the point sits between the two edges of the painted area, as a fraction. No data value is read. The texture is read down its middle column, the curve edge taking the top and the opposite edge the bottom. Typical use case: the fade under the curve of an area chart.
- [`VALUE_Y`](#fillstretchspan) measures the Y value at the point, in data units. The texture is read down its middle column, high values at the top. Typical use case: making a value readable from its color alone, as in a fill that reddens toward high values.
- [`VALUE_X`](#fillstretchspan) measures the X value at the point, in data units. The texture is read across its middle row, high values at the right. Typical use case: dimming the oldest samples of a live plot while the newest stay bright.
- [`MAGNITUDE`](#fillstretchspan) measures the distance from [`fill_baseline`](#fill_baseline), in data units, taken as a distance so a point above the baseline and a point as far below it measure the same. The texture is read down its middle column, the baseline at the bottom and the farthest point at the top. Typical use case: showing how far the data went from a reference, in either direction.

The three spans that measure data units need to know which two values the ends of the texture stand for. [`stretch_range_policy`](#stretch_range_policy) sets where those two values come from: the data itself, or the fixed window in [`stretch_range`](#stretch_range). A point measuring outside that range takes the color of the nearer end. [`LINE`](#fillstretchspan) measures no data value, so it reads neither property.

Since every span reads a single column or a single row, a texture meant for a stretched fill can be authored one pixel wide.

### Three-layer cascade

Each property is resolved in three layers: the built-in default, then the value the active Godot theme names, then the value assigned on this instance. A property counts as overridden as soon as it is assigned, whatever the value, and for an array property only assigning a new array counts.

See [`TauStyle`](style.md#three-layer-cascade) for the cascade and [`TauStyle`](style.md#theme-keys) for the grammar of the keys listed in [Theming](#theming).

### Theming

`TauLineFill` reads its keys from the `TauLine` **theme type variation**, whose base type is `Control`. See [`TauStyle`](style.md#theme-keys) for the grammar of a theme key and for how a theme type variation is looked up.

A theme resource using `TauLine` must include a base type declaration:

```gdscript
[resource]
TauLine/base_type = &"Control"
TauLine/constants/line_fill_mode_0 = 1
TauLine/colors/line_fill_color_0 = Color(0.2, 0.5, 0.9, 1)
```

Every key below carries a series index, written `i` in the table: `line_fill_color_0` is the color of the first series. A key also accepts a pane index appended as a second number, so `line_fill_color_0_1` sets the first series of the second pane only. See [`TauStyle`](style.md#theme-keys) for the full indexing rules.

The following theme entries are used:

| Theme property | Description |
| --- | --- |
| `line_fill_mode_i`: `int` | Maps to [`fill_mode`](#fill_mode) of entry `i`. The value is a [`FillMode`](#fillmode) member as an integer. Any other integer is an error and the field falls back to [`NONE`](#fillmode). |
| `line_fill_color_i`: `Color` | Maps to [`color`](#color) of entry `i`. |
| `line_fill_alpha_percent_i`: `int` | Maps to [`alpha`](#alpha) of entry `i`. Stored as a percentage, resolved as `percent / 100.0`. |
| `line_fill_texture_i`: `Texture2D` | Maps to [`texture`](#texture) of entry `i`. |
| `line_fill_texture_mode_i`: `int` | Maps to [`texture_mode`](#texture_mode) of entry `i`. The value is a [`FillTextureMode`](#filltexturemode) member as an integer. Any other integer is an error and the field falls back to [`STRETCH`](#filltexturemode). |
| `line_fill_texture_stretch_span_i`: `int` | Maps to [`stretch_span`](#stretch_span) of entry `i`. The value is a [`FillStretchSpan`](#fillstretchspan) member as an integer. Any other integer is an error and the field falls back to [`LINE`](#fillstretchspan). |
| `line_fill_texture_scale_percent_i`: `int` | Maps to [`tile_scale`](#tile_scale) of entry `i`. Stored as a percentage, resolved as `percent / 100.0`. |
| `line_fill_texture_rotation_deg_i`: `int` | Maps to [`tile_rotation_deg`](#tile_rotation_deg) of entry `i`, in degrees. |
| `line_fill_texture_offset_px_x_i`: `int` | Maps to the X component of [`tile_offset_px`](#tile_offset_px) of entry `i`, in pixels. |
| `line_fill_texture_offset_px_y_i`: `int` | Maps to the Y component of [`tile_offset_px`](#tile_offset_px) of entry `i`, in pixels. |

Three properties carry no theme key and are set from code alone: [`fill_baseline`](#fill_baseline), [`stretch_range_policy`](#stretch_range_policy), and [`stretch_range`](#stretch_range).

### Side effects

All properties are **visual-only**. A change triggers a redraw and never a layout recomputation.

### Example

```gdscript
var line_style := TauLineStyle.new()

# Series 0 is filled down to the zero line in a translucent blue.
var area := TauLineFill.new()
area.fill_mode = TauLineFill.FillMode.TO_BASELINE
area.color = Color(0.2, 0.5, 0.9)
area.alpha = 0.35
line_style.fills = [area]

var line_overlay := TauLineConfig.new()
line_overlay.style = line_style
```

### Notes

1. **A fill needs no curve.** A series whose [`TauLineStyle.line_widths_px`](line_style.md#line_widths_px) entry is `0` draws no line, and the fill is then everything the series paints. The upper edge of the area is the bare boundary of the painted shape.

2. **Settings that contradict each other are reported, never rejected.** A fill whose settings do not go together is reported once in the Godot output, as an error or as a warning, and the plot draws what it can: the setting it could not apply is left out. The one exception is a [`STACKED`](#fillmode) fill in an overlay that does not stack, which is dropped.

## Enums

### `FillMode`

Selects which area around the curve is painted.

| Value | Meaning |
|---|---|
| `NONE` | The series is left unpainted. |
| `TO_BASELINE` | The area between the curve and the flat level [`fill_baseline`](#fill_baseline) is painted. |
| `STACKED` | The area between the curve and the curve of the series below it in the stack is painted, so the overlay reads as a stacked area chart. The bottom curve is painted down to zero. Requires [`TauLineConfig.mode`](line_config.md#mode) to be [`STACKED`](line_config.md#linemode). |

---

### `StretchRangePolicy`

Selects where a value span reads the low end and the high end of the range it measures against. The low end takes one edge of the texture and the high end takes the other, so this choice decides which values the two edges stand for.

| Value | Meaning |
|---|---|
| `DOMAIN` | The two ends come from the data bounds of the axis the span measures on, taken before axis padding so the texture ends land on the data extremes. The gradient always covers the whole range of the data, and follows it as the data changes. |
| `CUSTOM` | The two ends come from [`stretch_range`](#stretch_range). A color stays tied to the same value as the data changes, and a point measuring outside the window is clamped to the nearer edge of the texture. This is what a threshold or a reference band needs. |

---

### `FillTextureMode`

Selects how [`texture`](#texture) is painted across the area.

| Value | Meaning |
|---|---|
| `STRETCH` | The texture is fitted across the area once and read as a color scale. This is the mode for a gradient. |
| `TILE` | The texture is repeated at its native pixel size. This is the mode for a motif such as dots or hatching. |

---

### `FillStretchSpan`

Selects what is measured at each point of the area under a [`STRETCH`](#filltexturemode) texture, and which axis of the texture the measurement is read along. The same gradient comes out differently from one span to the next. See [How a texture is painted](#how-a-texture-is-painted) for the typical use case of each span.

| Value | Meaning |
|---|---|
| `LINE` | Where the point sits between the curve and the opposite edge, as a fraction. No data value is read, so the gradient follows the shape of the area and stays put while the plot is zoomed or scrolled. The texture is read down its middle column, the curve edge taking the top and the opposite edge the bottom, so the whole texture is always on screen, both ends included. |
| `VALUE_Y` | The Y value at the point, in data units. Two points at the same Y value always share the same color, and a color keeps its meaning while the plot is zoomed. The texture is read down its middle column, high values at the top. |
| `VALUE_X` | The X value at the point, in data units. Two points at the same X value always share the same color. The texture is read across its middle row, high values at the right. |
| `MAGNITUDE` | The distance from [`fill_baseline`](#fill_baseline) in data units, whichever side of it the point is on, so a point above the baseline and a point as far below it share the same color. The texture is read down its middle column, the baseline at the bottom and the farthest point at the top. Not available under a [`STACKED`](#fillmode) fill, which has no baseline to measure from. |

## Constructor

### `new()`

```gdscript
TauLineFill.new() -> TauLineFill
```

Creates a new `TauLineFill` with every field at its built-in default and none of them marked as assigned.

## Properties

### fill_mode

`fill_mode`: [`FillMode`](#fillmode)

Which area around the curve is painted. Default is [`NONE`](#fillmode).

---

### fill_baseline

`fill_baseline`: `float`

The flat level a [`TO_BASELINE`](#fillmode) fill is painted to, in data units on the Y axis of the series. Default is `0.0`.

The area is painted between the curve and this level. The [`MAGNITUDE`](#fillstretchspan) span also measures its distance from this level. Ignored by the other [`fill_mode`](#fill_mode) values.

On a [`LOGARITHMIC`](axis_config.md#scale-enum) Y axis the level is placed like any data value, so a value at or below zero cannot be placed and the plot raises an error, see [note 2](#notes).

---

### stretch_range_policy

`stretch_range_policy`: [`StretchRangePolicy`](#stretchrangepolicy)

Where a value span reads the two ends of the range it measures against. Default is [`DOMAIN`](#stretchrangepolicy), which takes them from the data bounds of the axis the span measures on.

Only read by a [`STRETCH`](#filltexturemode) texture whose [`stretch_span`](#stretch_span) is [`VALUE_Y`](#fillstretchspan), [`VALUE_X`](#fillstretchspan), or [`MAGNITUDE`](#fillstretchspan). [`LINE`](#fillstretchspan) needs no range and never reads this property. Setting [`CUSTOM`](#stretchrangepolicy) on a fill that never reads it has no effect, and the plot raises a warning, see [note 2](#notes).

---

### stretch_range

`stretch_range`: `Vector2`

The fixed low end and high end of the measured range. Default is `Vector2.ZERO`.

Only read when [`stretch_range_policy`](#stretch_range_policy) is [`CUSTOM`](#stretchrangepolicy). `x` is the low end and `y` is the high end, both in data units. Swapping the two reverses the gradient.

What the two ends mean follows the span that reads them. For [`VALUE_Y`](#fillstretchspan) they are values on the Y axis of the series. For [`VALUE_X`](#fillstretchspan) they are values on the X axis. For [`MAGNITUDE`](#fillstretchspan) they are distances from [`fill_baseline`](#fill_baseline), so both stay at or above zero. A point measuring outside the window takes the color of the nearer end.

Two cases raise an error, see [note 2](#notes): the two ends being equal, which leaves no range to measure against, and [`VALUE_X`](#fillstretchspan) on a [categorical](axis_config.md#type-enum) X axis, which has no continuous X to place the ends on. Both fall back to reading the middle of the texture, so the area comes out in one flat color.

---

### color

`color`: `Color`

The flat color painted over the area. Default is the sentinel `NO_COLOR`, which is `Color(0, 0, 0, 0)` and means the color of the series is used instead, from [`TauXYStyle.series_colors`](xy_style.md#series_colors). A fully transparent color is therefore not an explicit fill color.

Ignored when [`texture`](#texture) holds a texture. The alpha of the resolved color is multiplied by [`alpha`](#alpha).

---

### alpha

`alpha`: `float`

Multiplier applied to the alpha of the painted area. Default is `0.5`.

Applies whether the paint came from [`color`](#color), from the color of the series, or from [`texture`](#texture). Values outside `0.0` to `1.0` are clamped into that range on assignment.

`0.0` on a filled area with no [`texture`](#texture) and no explicit [`color`](#color) paints nothing visible, and the plot raises a warning, see [note 2](#notes).

---

### texture

`texture`: `Texture2D`

The texture painted over the area. Default is `null`.

When set, it takes the place of [`color`](#color) and of the color of the series, and its own alpha is multiplied by [`alpha`](#alpha). A texture set on a fresh fill fades from the curve to the baseline with nothing else to set, since [`texture_mode`](#texture_mode) and [`stretch_span`](#stretch_span) default to the area-fade pair.

Assign a new `Texture2D` rather than mutating the one already assigned. A change made in place is not detected and the plot keeps the previous resolution.

---

### texture_mode

`texture_mode`: [`FillTextureMode`](#filltexturemode)

How [`texture`](#texture) is painted across the area. Default is [`STRETCH`](#filltexturemode).

Ignored when [`texture`](#texture) is `null`.

---

### stretch_span

`stretch_span`: [`FillStretchSpan`](#fillstretchspan)

What is measured at each point of the area to pick its color from a stretched texture. Default is [`LINE`](#fillstretchspan).

Ignored when [`texture`](#texture) is `null` or when [`texture_mode`](#texture_mode) is [`TILE`](#filltexturemode).

---

### tile_scale

`tile_scale`: `float`

Uniform scale applied to the grid of tiles. Default is `1.0`, which puts one tile at the native pixel size of the texture on screen.

Only used when [`texture_mode`](#texture_mode) is [`TILE`](#filltexturemode), and ignored when [`texture`](#texture) is `null`. The tiles stay square whatever the shape of the pane.

`0.0` or below paints no tile at all, and the plot raises a warning, see [note 2](#notes).

---

### tile_rotation_deg

`tile_rotation_deg`: `float`

Rotation of the grid of tiles in degrees, turned around the center of the pane so the motif holds still as data updates. Default is `0.0`.

Only used when [`texture_mode`](#texture_mode) is [`TILE`](#filltexturemode), and ignored when [`texture`](#texture) is `null`.

---

### tile_offset_px

`tile_offset_px`: `Vector2`

Translation applied to the grid of tiles, after rotation. Default is `Vector2.ZERO`.

Only used when [`texture_mode`](#texture_mode) is [`TILE`](#filltexturemode), and ignored when [`texture`](#texture) is `null`. The offset is in screen pixels, so animating one component slides the motif along the matching screen axis whatever [`tile_rotation_deg`](#tile_rotation_deg) and [`tile_scale`](#tile_scale) hold.

## Related Classes

* [`TauStyle`](style.md) Base class. Defines the cascade, the cycle indexing, the theme key grammar, and the field-by-field merge.
* [`TauLineStyle`](line_style.md) Holds the fill cycle in [`fills`](line_style.md#fills).
* [`TauLineConfig`](line_config.md) Configures the line overlay the fill is painted in. Its [`mode`](line_config.md#mode) gates the [`STACKED`](#fillmode) fill.
* [`TauXYStyle`](xy_style.md) Supplies the color of the series a fill falls back to, through [`series_colors`](xy_style.md#series_colors).
* [`TauAxisConfig`](axis_config.md) Configures the axes the fill is mapped onto, including the scale that constrains [`fill_baseline`](#fill_baseline).