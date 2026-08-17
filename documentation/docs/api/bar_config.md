# TauBarConfig

!!! info ""
    **Inherits:** [`TauPaneOverlayConfig`](pane_overlay_config.md)

Configures a [`BAR`](tau_plot.md#paneoverlaytype) overlay rendered inside a pane.

## Description

`TauBarConfig` is the concrete [`TauPaneOverlayConfig`](pane_overlay_config.md) subclass for bar overlays. Place one instance in [`TauPaneConfig.overlays`](pane_config.md#overlays) to draw bars in that pane. The plot sets [`overlay_type`](pane_overlay_config.md#overlay_type) to [`BAR`](tau_plot.md#paneoverlaytype) at construction.

The [`mode`](#mode) controls how bars from multiple series at the same X position relate to each other:

- [`GROUPED`](#barmode) places them side by side.
- [`STACKED`](#barmode) stacks them in the direction of the Y axis so each bar begins where the previous one ended.
- [`INDEPENDENT`](#barmode) draws each series as if the others do not exist, which causes overlap.

Two properties shape a stack:

- [`stacked_normalization`](#stacked_normalization) sets what each stack is scaled to: the raw sum, `1.0`, or `100.0`.
- [`stacked_negative_policy`](#stacked_negative_policy) sets how a negative value enters the stack. Bars accept [`DIVERGING`](tau_plot.md#stackednegativepolicy) and [`SKIP_NEGATIVES`](tau_plot.md#stackednegativepolicy). [`SIGNED_SUM`](tau_plot.md#stackednegativepolicy) is a validation error and [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) aborts, because a dip below the previous layer cannot be drawn without overlapping rectangles.

[`StackedNormalization`](tau_plot.md#stackednormalization) and [`StackedNegativePolicy`](tau_plot.md#stackednegativepolicy) are shared with [`TauLineConfig`](line_config.md) and are reached through the [`TauPlot`](tau_plot.md) namespace.

The **bar width policy** controls how bar widths are computed:

- [`AUTO`](#barwidthpolicy) selects [`CATEGORY_WIDTH_FRACTION`](#barwidthpolicy) for categorical X axes and [`NEIGHBOR_SPACING_FRACTION`](#barwidthpolicy) for continuous X axes.
- [`THEME`](#barwidthpolicy) reads pixel-based constants from the Godot theme via [`TauBarStyle`](bar_style.md).
- [`CATEGORY_WIDTH_FRACTION`](#barwidthpolicy) allocates each bar a fixed portion of the categorical slot. The slot is divided among all series in the group, with [`category_width_fraction`](#category_width_fraction) controlling the total group span and [`intra_group_gap_fraction`](#intra_group_gap_fraction) the spacing between bars. Valid only on categorical X axes.
- [`DATA_UNITS`](#barwidthpolicy) gives bars a size anchored to the data coordinate system. Width and gap are expressed in X data units on a [linear scale](axis_config.md#scale-enum), or as multiplicative factors on a [logarithmic scale](axis_config.md#scale-enum). Valid only on continuous X axes.
- [`NEIGHBOR_SPACING_FRACTION`](#barwidthpolicy) adapts bar width to the local density of samples. Each bar or group takes a fraction of the distance to the nearest neighboring X value, so bars stay proportionate across unevenly spaced data. Valid only on continuous X axes.

The width and gap properties of the active policy are checked when the plot is built. A value outside its range is a validation error and [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) aborts, leaving the previous plot untouched. Properties belonging to another policy are not read and not checked.

[`mode`](#mode) affects layout and domain computation on its own. [`stacked_normalization`](#stacked_normalization) and [`stacked_negative_policy`](#stacked_negative_policy) affect it while [`mode`](#mode) is [`STACKED`](#barmode). Every other property on this class is visual-only and triggers a redraw without rebuilding the layout.

Visual appearance beyond width is controlled by [`style`](#style), which holds the `StyleBox` of a bar, its hovered-state counterpart, and the pixel-based sizing constants. Per-sample color, alpha, and `StyleBox` overrides are applied through [`bar_visual_callbacks`](#bar_visual_callbacks) or through [`BarVisualAttributes`](bar_visual_attributes.md) on the series binding. See [`TauPaneOverlayConfig`](pane_overlay_config.md#per-sample-overrides) for the order the two mechanisms resolve in.

After [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) succeeds, the plot holds a reference to this instance. Mutating a property at runtime is supported, but requires calling [`TauPlot.queue_refresh()`](tau_plot.md#queue_refresh) to apply the change.

### Example

```gdscript
var bar_overlay := TauBarConfig.new()
bar_overlay.mode = TauBarConfig.BarMode.GROUPED
bar_overlay.bar_width_policy = TauBarConfig.BarWidthPolicy.DATA_UNITS
bar_overlay.bar_width_x_units = 0.8
bar_overlay.bar_gap_x_units = 0.05

var pane := TauPaneConfig.new()
pane.y_left_axis = TauAxisConfig.new()
pane.overlays = [bar_overlay]
```

### Notes

1. **Two stacked overlays on one axis must agree.** When a [`STACKED`](#barmode) bar overlay and a [`STACKED`](line_config.md#linemode) line overlay draw against the same Y axis of the same pane, they must declare the same [`stacked_normalization`](#stacked_normalization) and the same [`stacked_negative_policy`](#stacked_negative_policy). Both feed the range of that axis, and a disagreement is a validation error that aborts [`TauPlot.plot_xy()`](tau_plot.md#plot_xy).

## Enums

### `BarMode`

Controls how bars from multiple series at the same X position are arranged relative to each other.

| Value | Meaning |
|---|---|
| `GROUPED` | Bars from different series at the same X position are placed side by side within the allocated slot width. |
| `STACKED` | Bars from different series at the same X position are stacked in the direction of the Y axis, each starting where the previous one ended. |
| `INDEPENDENT` | Each series is drawn independently of the others. Bars at the same X position overlap. |

---

### `BarWidthPolicy`

Selects the strategy used to compute bar widths and intragroup gaps.

| Value | Meaning |
|---|---|
| `AUTO` | Resolves to [`CATEGORY_WIDTH_FRACTION`](#barwidthpolicy) for categorical X axes and [`NEIGHBOR_SPACING_FRACTION`](#barwidthpolicy) for continuous X axes. |
| `THEME` | Reads pixel-based width and gap constants from the Godot theme via [`TauBarStyle.bar_width_px`](bar_style.md#bar_width_px) and [`TauBarStyle.bar_intragroup_gap_px`](bar_style.md#bar_intragroup_gap_px). |
| `CATEGORY_WIDTH_FRACTION` | Derives the bar width from the categorical slot width using [`category_width_fraction`](#category_width_fraction) and [`intra_group_gap_fraction`](#intra_group_gap_fraction). Valid only on categorical X axes. |
| `DATA_UNITS` | Expresses bar width in X data units. On a [linear scale](axis_config.md#scale-enum), uses [`bar_width_x_units`](#bar_width_x_units) and [`bar_gap_x_units`](#bar_gap_x_units). On a [logarithmic scale](axis_config.md#scale-enum), uses [`bar_width_log_factor`](#bar_width_log_factor) and [`bar_gap_log_factor`](#bar_gap_log_factor). Valid only on continuous X axes. |
| `NEIGHBOR_SPACING_FRACTION` | Derives the bar width from the local spacing between neighboring X samples, using [`neighbor_spacing_fraction`](#neighbor_spacing_fraction) and [`neighbor_gap_fraction`](#neighbor_gap_fraction). Valid only on continuous X axes. |

## Constructor

### `new()`

```gdscript
TauBarConfig.new() -> TauBarConfig
```

Creates a new `TauBarConfig` with all properties set to their built-in defaults and [`overlay_type`](pane_overlay_config.md#overlay_type) set to [`BAR`](tau_plot.md#paneoverlaytype). The instance is ready to place in [`TauPaneConfig.overlays`](pane_config.md#overlays).

## Properties

### mode

`mode`: [`BarMode`](#barmode)

The arrangement mode for bars from multiple series at the same X position. Default is [`GROUPED`](#barmode).

[`GROUPED`](#barmode) and [`STACKED`](#barmode) require a [`SHARED_X`](dataset.md#mode)
[`Dataset`](dataset.md). [`STACKED`](#barmode) additionally requires all bound series to share
the same Y axis, and that Y axis must use a [`LINEAR`](axis_config.md#scale-enum) scale. An unmet
requirement is a validation error and [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) aborts.
[`INDEPENDENT`](#barmode) has no dataset or axis constraints.

Changing this property triggers a full layout recomputation on the next refresh, because the mode decides whether the Y domain covers single values or stacked totals.

---

### stacked_normalization

`stacked_normalization`: [`StackedNormalization`](tau_plot.md#stackednormalization)

What each stack is scaled to. Default is [`NONE`](tau_plot.md#stackednormalization).

Only read when [`mode`](#mode) is [`STACKED`](#barmode), and ignored in the two other modes. While the mode is [`STACKED`](#barmode), changing this property triggers a full layout recomputation on the next refresh, because [`FRACTION`](tau_plot.md#stackednormalization) and [`PERCENT`](tau_plot.md#stackednormalization) pin the Y domain to the normalized total.

---

### stacked_negative_policy

`stacked_negative_policy`: [`StackedNegativePolicy`](tau_plot.md#stackednegativepolicy)

How a negative sample enters a stack. Default is [`SKIP_NEGATIVES`](tau_plot.md#stackednegativepolicy).

Only read when [`mode`](#mode) is [`STACKED`](#barmode), and ignored in the two other modes. [`SIGNED_SUM`](tau_plot.md#stackednegativepolicy) is rejected for bars: it dips a stack below the layer under it, which bar geometry can only draw as overlapping rectangles. Declaring it is a validation error and [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) aborts, whatever the data holds.

While the mode is [`STACKED`](#barmode), changing this property triggers a full layout recomputation on the next refresh, because the policy decides whether the Y domain reaches below zero.

---

### bar_width_policy

`bar_width_policy`: [`BarWidthPolicy`](#barwidthpolicy)

The strategy used to compute bar widths. Default is [`AUTO`](#barwidthpolicy).

Determines which set of width and gap properties is active (see [`BarWidthPolicy`](#barwidthpolicy)). Properties that do not belong to the active policy have no effect.

[`CATEGORY_WIDTH_FRACTION`](#barwidthpolicy) is only valid for categorical X axes. [`DATA_UNITS`](#barwidthpolicy) and [`NEIGHBOR_SPACING_FRACTION`](#barwidthpolicy) are only valid for continuous X axes. Any other pairing is a validation error and [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) aborts. [`AUTO`](#barwidthpolicy) and [`THEME`](#barwidthpolicy) are valid on both axis types.

This property is visual-only and triggers a redraw without rebuilding the layout.

---

### category_width_fraction

`category_width_fraction`: `float`

The fraction of the categorical slot width occupied by the entire group of bars at one X position. Default is `0.9`.

Only used when the active policy is [`CATEGORY_WIDTH_FRACTION`](#barwidthpolicy). Valid range is `]0.0, 1.0]`, and a value outside it is a validation error. A value of `0.9` means the group spans 90% of the slot, leaving 10% as inter-group whitespace. In [`GROUPED`](#barmode) mode, individual bar widths are derived so that all bars and their intragroup gaps fit within this fraction. This property is visual-only.

---

### intra_group_gap_fraction

`intra_group_gap_fraction`: `float`

The gap between adjacent bars in a [`GROUPED`](#barmode) cluster, expressed as a fraction of the individual bar width. Default is `0.1`.

Only used when the active policy is [`CATEGORY_WIDTH_FRACTION`](#barwidthpolicy) and [`mode`](#mode) is [`GROUPED`](#barmode). Valid range is `[0.0, 1.0]`, and a value outside it is a validation error. This property is visual-only.

---

### bar_width_x_units

`bar_width_x_units`: `float`

The bar width expressed in X data units, for use on a linear scale. Default is `1.0`.

Only used when the active policy is [`DATA_UNITS`](#barwidthpolicy) and the X scale is [`LINEAR`](axis_config.md#scale-enum). Must be at or above `0.0`, and a lower value is a validation error. Bars keep a constant width in data units regardless of zoom or pane size. This property is visual-only.

---

### bar_gap_x_units

`bar_gap_x_units`: `float`

The gap between bars in a [`GROUPED`](#barmode) cluster, expressed in X data units, for use on a linear scale. Default is `0.0`.

Only used when the active policy is [`DATA_UNITS`](#barwidthpolicy), the X scale is [`LINEAR`](axis_config.md#scale-enum), and [`mode`](#mode) is [`GROUPED`](#barmode). Must be at or above `0.0`, and a lower value is a validation error. This property is visual-only.

---

### bar_width_log_factor

`bar_width_log_factor`: `float`

The bar width expressed as a multiplicative factor around the bar's X value, for use on a logarithmic scale. Default is `1.5`.

Only used when the active policy is [`DATA_UNITS`](#barwidthpolicy) and the X scale is [`LOGARITHMIC`](axis_config.md#scale-enum). Must be at or above `1.0`, and a lower value is a validation error. A value of `2.0` places the bar edges at `X / sqrt(2)` and `X * sqrt(2)`, giving a consistent relative thickness across decades. `1.0` produces zero-width bars. This property is visual-only.

---

### bar_gap_log_factor

`bar_gap_log_factor`: `float`

The gap between bars in a [`GROUPED`](#barmode) cluster, expressed as a multiplicative factor relative to the bar width, for use on a logarithmic scale. Default is `1.0`.

Only used when the active policy is [`DATA_UNITS`](#barwidthpolicy), the X scale is [`LOGARITHMIC`](axis_config.md#scale-enum), and [`mode`](#mode) is [`GROUPED`](#barmode). Must be at or above `1.0`, and a lower value is a validation error. A value of `1.0` produces no extra gap. This property is visual-only.

---

### neighbor_spacing_fraction

`neighbor_spacing_fraction`: `float`

The fraction of the local spacing between neighboring X samples used as the bar or group width. Default is `0.8`.

Only used when the active policy is [`NEIGHBOR_SPACING_FRACTION`](#barwidthpolicy). Valid range is `]0.0, 1.0]`, and a value outside it is a validation error. In [`GROUPED`](#barmode) mode this fraction applies to the total group width. In [`STACKED`](#barmode) and [`INDEPENDENT`](#barmode) modes it applies to the individual bar width. Bars automatically become narrower in dense regions and wider in sparse regions. This property is visual-only.

---

### neighbor_gap_fraction

`neighbor_gap_fraction`: `float`

The gap between bars in a [`GROUPED`](#barmode) cluster, expressed as a fraction of the individual bar width, for use with the [`NEIGHBOR_SPACING_FRACTION`](#barwidthpolicy) policy. Default is `0.1`.

Only used when the active policy is [`NEIGHBOR_SPACING_FRACTION`](#barwidthpolicy) and [`mode`](#mode) is [`GROUPED`](#barmode). Must be at or above `0.0`, and a lower value is a validation error. This property is visual-only.

---

### style

`style`: [`TauBarStyle`](bar_style.md)

The visual style applied to bars in this overlay: the `StyleBox` of a bar, the `StyleBox` of the hovered bar, and the pixel width and intragroup gap read under the [`THEME`](#barwidthpolicy) policy. Default is a freshly constructed [`TauBarStyle`](bar_style.md) with all built-in defaults.

Never `null`. Modify properties directly on the instance. Any property left unassigned on this instance can still be set by the active Godot theme. Multiple `TauBarConfig` instances can share the same [`TauBarStyle`](bar_style.md) resource.

---

### bar_visual_callbacks

`bar_visual_callbacks`: [`BarVisualCallbacks`](bar_visual_callbacks.md)

Typed accessor for per-sample visual callbacks on this bar overlay. Default is `null`.

Reads and writes the inherited [`TauPaneOverlayConfig.visual_callbacks`](pane_overlay_config.md#visual_callbacks) property cast to [`BarVisualCallbacks`](bar_visual_callbacks.md). Assigning a non-[`BarVisualCallbacks`](bar_visual_callbacks.md) instance through the base property and then reading `bar_visual_callbacks` returns `null`. Assign a [`BarVisualCallbacks`](bar_visual_callbacks.md) instance here to override color, alpha, or `StyleBox` per sample at draw time. See [`TauPaneOverlayConfig`](pane_overlay_config.md#per-sample-overrides) for the order a callback resolves in against a [`BarVisualAttributes`](bar_visual_attributes.md) buffer and the style property.

`bar_visual_callbacks` is not serializable. The property is not exported and cannot be saved in a `.tres` resource file. Assign it at runtime only.

## Related Classes

* [`TauPlot`](tau_plot.md) The plot node. Consumes `TauBarConfig` during layout and rendering, and holds the [`StackedNormalization`](tau_plot.md#stackednormalization) and [`StackedNegativePolicy`](tau_plot.md#stackednegativepolicy) enums.
* [`TauPaneOverlayConfig`](pane_overlay_config.md) Base class. Defines [`overlay_type`](pane_overlay_config.md#overlay_type), [`z_order`](pane_overlay_config.md#z_order), [`hoverable`](pane_overlay_config.md#hoverable), and [`visual_callbacks`](pane_overlay_config.md#visual_callbacks).
* [`TauPaneConfig`](pane_config.md) Holds the overlay in its [`overlays`](pane_config.md#overlays) array.
* [`TauAxisConfig`](axis_config.md) Configures the axes whose type and scale decide which width policies are valid.
* [`Dataset`](dataset.md) The data model. Its [`SHARED_X`](dataset.md#mode) mode is required by [`GROUPED`](#barmode) and [`STACKED`](#barmode).
* [`TauBarStyle`](bar_style.md) Controls visual appearance. Owned by this config via [`style`](#style).
* [`BarVisualCallbacks`](bar_visual_callbacks.md) Supplies per-sample color, alpha, and `StyleBox` overrides via callbacks.
* [`BarVisualAttributes`](bar_visual_attributes.md) Supplies per-sample color and alpha overrides via pre-built buffers.
* [`TauXYStyle`](xy_style.md) Provides the series color cycle applied when no per-sample override supplies a color.
* [`TauScatterConfig`](scatter_config.md) Sibling overlay configuration for scatter overlays.
* [`TauLineConfig`](line_config.md) Sibling overlay configuration for line overlays, and the other user of the two stacking enums.