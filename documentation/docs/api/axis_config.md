# TauAxisConfig

!!! info ""
    **Inherits:** `Resource`  

Configures a single axis.

## Description

`TauAxisConfig` describes how one axis behaves and what it displays. It is assigned to [`TauXYConfig.x_axis`](xy_config.md#x_axis) for the primary X axis, to [`TauXYConfig.secondary_x_axis`](xy_config.md#secondary_x_axis) for the optional secondary X axis, and to the Y axis slots on [`TauPaneConfig`](pane_config.md): [`y_left_axis`](pane_config.md#y_left_axis), [`y_right_axis`](pane_config.md#y_right_axis), [`y_top_axis`](pane_config.md#y_top_axis), [`y_bottom_axis`](pane_config.md#y_bottom_axis).

The **type** property determines the fundamental rendering mode:

- A [`CATEGORICAL`](#type-enum) axis displays discrete string labels at fixed positions, one per unique X value in the bound series. 
- A [`CONTINUOUS`](#type-enum) axis maps numeric values to screen positions along a computed domain. 

Most properties only apply to `CONTINUOUS` axes and are ignored on `CATEGORICAL` ones.

For `CONTINUOUS` axes, the [`scale`](#scale) property controls how data values map to screen positions:

- [`LINEAR`](#scale-enum) maps equal differences in value to equal distances on the axis. 
- [`LOGARITHMIC`](#scale-enum) compresses large spans by applying a base-10 logarithm to data values before mapping.

The **domain** is the data range visible on the axis. By default it is computed from the data, expanded by padding, and optionally extended to include zero. [`range_override_enabled`](#range_override_enabled) bypasses all of that and pins the domain to [`min_override`](#min_override) and [`max_override`](#max_override).

**Domain padding** controls the margin added beyond the data min and max. [`domain_padding_mode`](#domain_padding_mode) selects the padding strategy. [`domain_padding_min`](#domain_padding_min) and [`domain_padding_max`](#domain_padding_max) supply the padding amounts when [`FRACTION`](#domainpaddingmode) or [`DATA_UNITS`](#domainpaddingmode) is active. Padding also acts as a buffer for live data: when new samples are appended and their values fall within the padded domain, the axis range does not need to be recomputed.

**Tick count and label overlap** govern how many ticks appear and how collisions between their labels are resolved. [`tick_count_preferred`](#tick_count_preferred) sets a target tick count for linear scales. [`overlap_strategy`](#overlap_strategy) selects the collision resolution method. [`min_label_spacing_px`](#min_label_spacing_px) sets the minimum pixel gap between adjacent labels.

The **title** is displayed next to the axis. It supports BBCode and is hidden when the string is empty. [`title_orientation`](#title_orientation), [`title_alignment`](#title_alignment), and [`title_text_alignment`](#title_text_alignment) control how the title is laid out relative to the axis.

After [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) succeeds, the plot holds a reference to every `TauAxisConfig` instance it received. Mutating a property at runtime is supported, but requires calling [`TauPlot.queue_refresh()`](tau_plot.md#queue_refresh) to apply the change. Runtime mutation is not yet supported by every property: see [Runtime Configuration Change Limitations](../runtime-configuration-change-limitations.md).

### Example

```gdscript
# Progress per month: one category per month on X, a percentage on Y.
var x_axis := TauAxisConfig.new()
x_axis.title = "Month"
x_axis.type = TauAxisConfig.Type.CATEGORICAL

var y_axis := TauAxisConfig.new()
y_axis.title = "Progress"
y_axis.type = TauAxisConfig.Type.CONTINUOUS
# Title at the far end of the axis, six ticks rather than the default five.
y_axis.title_alignment = TauAxisConfig.TitleAlignment.END
y_axis.tick_count_preferred = 6
# Tick labels are plain numbers, so append the unit.
y_axis.format_tick_label = func(label: String) -> String:
	return label + "%"

var pane := TauPaneConfig.new()
pane.y_left_axis = y_axis

var config := TauXYConfig.new()
config.x_axis = x_axis
config.panes = [pane]
```

## Enums

### `Type` { #type-enum }

Determines whether the axis displays discrete categories or a continuous numeric range.

| Value | Meaning |
|---|---|
| `CATEGORICAL` | The axis displays one labeled position per unique X value in the bound series. |
| `CONTINUOUS` | The axis maps numeric values to screen positions along a computed or overridden domain. |

---

### `Scale` { #scale-enum }

Controls how data values are mapped to screen positions on a `CONTINUOUS` axis.

| Value | Meaning |
|---|---|
| `LINEAR` | Equal differences in value map to equal distances along the axis. |
| `LOGARITHMIC` | Values are mapped using a base-10 logarithm, compressing large numeric spans. |

---

### `TitleOrientation`

Controls the rendering orientation of the axis title text.

| Value | Meaning |
|---|---|
| `AUTO` | Derives the orientation from the axis edge: horizontal for bottom and top axes, vertical for left and right axes. |
| `HORIZONTAL` | The title is always rendered horizontally. |
| `VERTICAL` | The title is always rendered vertically. |

---

### `TitleAlignment`

Controls where the title is placed along the axis direction.

| Value | Meaning |
|---|---|
| `BEGIN` | The title is aligned to the starting edge of the axis. For a horizontal axis this is the left edge. For a vertical axis this is the bottom of the pane. |
| `CENTER` | The title is centered along the axis. |
| `END` | The title is aligned to the far edge of the axis. For a horizontal axis this is the right edge. For a vertical axis this is the top of the pane. |

---

### `TextAlignment`

Controls the horizontal alignment of the title text when it is rendered horizontally.

| Value | Meaning |
|---|---|
| `LEFT` | The title text is left-aligned. |
| `CENTER` | The title text is centered. |
| `RIGHT` | The title text is right-aligned. |

---

### `OverlapStrategy`

Determines how the plot resolves overlapping tick labels.

| Value | Meaning |
|---|---|
| `NONE` | No overlap prevention is applied. Labels are drawn at every tick regardless of collisions. |
| `REDUCE_COUNT` | The tick count is reduced until labels no longer overlap. Not valid for `CATEGORICAL` axes. |
| `SKIP_LABELS` | All ticks are kept, but labels that would overlap a previously drawn label are not rendered. |

---

### `DomainPaddingMode`

Sets how the extra space added at each end of the axis is measured. The axis range normally starts at the data minimum and ends at the data maximum. Padding extends that range so data points do not sit right at the edge.

| Value | Meaning |
|---|---|
| `AUTO` | The plot picks a sensible amount automatically. When [`include_zero_in_domain`](#include_zero_in_domain) is `true` on a linear scale, no space is added at the low end and 5% of the data span is added at the high end. Otherwise 5% is added at both ends. |
| `NONE` | No space is added. The axis starts exactly at the data minimum and ends exactly at the data maximum. |
| `FRACTION` | The space is a fraction of the data span, given by [`domain_padding_min`](#domain_padding_min) and [`domain_padding_max`](#domain_padding_max). A value of `0.05` adds 5% of the span. On a [`LOGARITHMIC`](#scale-enum) scale the fraction applies to the log-span instead. |
| `DATA_UNITS` | The space is a fixed amount in data units, given by [`domain_padding_min`](#domain_padding_min) and [`domain_padding_max`](#domain_padding_max). A value of `10.0` always adds exactly 10 units regardless of the data span. |

## Constructor

### `new()`

```gdscript
TauAxisConfig.new() -> TauAxisConfig
```

Creates a new `TauAxisConfig` with all properties set to their built-in defaults. The instance is ready to assign to an axis slot immediately.

## Properties

### type

`type`: [`Type`](#type-enum)

The axis type. Default is [`CONTINUOUS`](#type-enum).

Determines whether the axis renders discrete category labels or a continuous numeric scale. Most other properties only take effect when this is [`CONTINUOUS`](#type-enum).

On the primary X axis the type constrains the [`Dataset`](dataset.md) it can be plotted against. [`CATEGORICAL`](#type-enum) requires a dataset whose X element type is [`CATEGORY`](dataset.md#xelementtype) and whose mode is [`SHARED_X`](dataset.md#mode). [`CONTINUOUS`](#type-enum) requires an X element type of [`NUMERIC`](dataset.md#xelementtype). A mismatch is a validation error and [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) aborts.

[`CATEGORICAL`](#type-enum) applies to the primary X axis only. On [`TauXYConfig.secondary_x_axis`](xy_config.md#secondary_x_axis) it is a validation error. On a Y axis slot of [`TauPaneConfig`](pane_config.md) it is ignored silently: the axis is resolved and drawn as [`CONTINUOUS`](#type-enum), with no error and no warning.

---

### scale

`scale`: [`Scale`](#scale-enum)

The mapping scale. Default is [`LINEAR`](#scale-enum).

Only used when [`type`](#type) is [`CONTINUOUS`](#type-enum). Controls whether data values are distributed evenly or logarithmically along the axis.

---

### inverted

`inverted`: `bool`

By default, a vertical axis draws the minimum value at the bottom and the maximum at the top. A horizontal axis draws the minimum on the left and the maximum on the right. If `true`, both directions are flipped. Default is `false`.

Works with both `CONTINUOUS` and `CATEGORICAL` axes. Has no effect when the `TauAxisConfig` is assigned to [`TauXYConfig.secondary_x_axis`](xy_config.md#secondary_x_axis), because the secondary axis domain is derived from the primary through [`TauXYConfig.secondary_x_axis_transform`](xy_config.md#secondary_x_axis_transform).

---

### include_zero_in_domain

`include_zero_in_domain`: `bool`

If `true`, the computed domain is expanded so that zero is always within the visible range. Default is `true`.

Only used when [`type`](#type) is [`CONTINUOUS`](#type-enum) and [`range_override_enabled`](#range_override_enabled) is `false`. Has no effect when the `TauAxisConfig` is assigned to [`TauXYConfig.secondary_x_axis`](xy_config.md#secondary_x_axis). Useful for bar charts where bars originate from zero. Set to `false` when the data range does not contain zero and showing it would waste visible space.

---

### title

`title`: `String`

The descriptive title displayed next to the axis. Default is `""`.

Supports BBCode. The title is hidden when the string is empty.

---

### title_orientation

`title_orientation`: [`TitleOrientation`](#titleorientation)

The rendering orientation of the title text. Default is [`AUTO`](#titleorientation).

[`AUTO`](#titleorientation) derives the orientation from the axis edge: horizontal for bottom and top axes, vertical for left and right axes.

---

### title_alignment

`title_alignment`: [`TitleAlignment`](#titlealignment)

The placement of the title along the axis direction. Default is [`CENTER`](#titlealignment).

---

### title_text_alignment

`title_text_alignment`: [`TextAlignment`](#textalignment)

The horizontal text alignment when the title is rendered horizontally. Default is [`CENTER`](#textalignment).

Has no effect on vertically oriented titles.

---

### format_tick_label

`format_tick_label`: `Callable`

An optional callback that formats tick label strings before they are rendered. Default is an invalid `Callable`.

If invalid, the axis renders the default label string. If valid, the callback is invoked once per tick and its return value replaces the default label. A common use is appending a unit to every label, for example turning `"42"` into `"42 kg"`. The callback signature is:

```gdscript
func(p_label: String) -> String
```

`p_label` is the default label string produced by the axis. The return value is the string displayed on the axis.

`format_tick_label` is not serializable. The property is not exported and cannot be saved in a `.tres` resource file. Assign it at runtime only.

---

### tick_count_preferred

`tick_count_preferred`: `int`

The preferred number of ticks on the axis. Default is `5`.

Only used when [`type`](#type) is [`CONTINUOUS`](#type-enum) and [`scale`](#scale) is [`LINEAR`](#scale-enum). Has no effect on [`LOGARITHMIC`](#scale-enum) scales, where tick positions follow decade boundaries. The actual tick count may differ from this preference.

Values below `2` are treated as `2`. [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) pushes a warning naming the axis when that happens, and continues.

---

### overlap_strategy

`overlap_strategy`: [`OverlapStrategy`](#overlapstrategy)

The strategy used to prevent tick labels from overlapping each other. Default is [`SKIP_LABELS`](#overlapstrategy).

[`REDUCE_COUNT`](#overlapstrategy) is not valid for [`CATEGORICAL`](#type-enum) axes. On one it pushes a warning and falls back to [`SKIP_LABELS`](#overlapstrategy).

---

### min_label_spacing_px

`min_label_spacing_px`: `int`

The minimum pixel gap between adjacent tick labels. Default is `8`.

The overlap strategy uses this value to decide whether two labels are too close.

---

### range_override_enabled

`range_override_enabled`: `bool`

If `true`, the axis domain is fixed to [`min_override`](#min_override) and [`max_override`](#max_override) instead of being computed from the data. Default is `false`.

Only used when [`type`](#type) is [`CONTINUOUS`](#type-enum). When enabled, [`include_zero_in_domain`](#include_zero_in_domain) and [`domain_padding_mode`](#domain_padding_mode) have no effect.

Enabling it puts the two bounds under validation, on every axis of the plot. [`min_override`](#min_override) above [`max_override`](#max_override) is a validation error, and on a [`LOGARITHMIC`](#scale-enum) axis a bound at or below `0.0` is a validation error. Either one aborts [`TauPlot.plot_xy()`](tau_plot.md#plot_xy).

---

### min_override

`min_override`: `float`

The minimum value of the fixed axis domain. Default is `0.0`.

Only used when [`range_override_enabled`](#range_override_enabled) is `true`. Must be at or below [`max_override`](#max_override), and strictly above `0.0` when [`scale`](#scale) is [`LOGARITHMIC`](#scale-enum).

---

### max_override

`max_override`: `float`

The maximum value of the fixed axis domain. Default is `1.0`.

Only used when [`range_override_enabled`](#range_override_enabled) is `true`. Must be at or above [`min_override`](#min_override), and strictly above `0.0` when [`scale`](#scale) is [`LOGARITHMIC`](#scale-enum).

---

### domain_padding_mode

`domain_padding_mode`: [`DomainPaddingMode`](#domainpaddingmode)

The strategy for padding the computed domain beyond the data min and max. Default is [`AUTO`](#domainpaddingmode).

Only used when [`type`](#type) is [`CONTINUOUS`](#type-enum) and [`range_override_enabled`](#range_override_enabled) is `false`. Has no effect when the `TauAxisConfig` is assigned to [`TauXYConfig.secondary_x_axis`](xy_config.md#secondary_x_axis), because the secondary axis domain is derived from the primary through [`TauXYConfig.secondary_x_axis_transform`](xy_config.md#secondary_x_axis_transform).

---

### domain_padding_min

`domain_padding_min`: `float`

The padding amount applied to the min side of the domain. Default is `0.05`.

Ignored when [`domain_padding_mode`](#domain_padding_mode) is [`AUTO`](#domainpaddingmode) or [`NONE`](#domainpaddingmode). In [`FRACTION`](#domainpaddingmode) mode, `0.05` means 5% of the data span. In [`DATA_UNITS`](#domainpaddingmode) mode, the value is in data units. On a [`LOGARITHMIC`](#scale-enum) scale with [`FRACTION`](#domainpaddingmode) mode, the fraction applies to the log-span.

---

### domain_padding_max

`domain_padding_max`: `float`

The padding amount applied to the max side of the domain. Default is `0.05`.

Follows the same rules as [`domain_padding_min`](#domain_padding_min).

## Related Classes

* [`TauPlot`](tau_plot.md) The plot node. Consumes `TauAxisConfig` instances during layout and rendering.
* [`TauXYConfig`](xy_config.md) Holds the primary X axis via [`x_axis`](xy_config.md#x_axis) and the optional secondary X axis via [`secondary_x_axis`](xy_config.md#secondary_x_axis).
* [`TauPaneConfig`](pane_config.md) Holds up to four Y axis slots, each accepting an `TauAxisConfig` instance.
* [`Dataset`](dataset.md) Supplies the values the axis maps. Its mode and X element type constrain [`type`](#type).
* [`TauXYStyle`](xy_style.md) Controls the visual appearance of axes: tick dimensions, label font, colors, and padding.