# TauLineConfig

!!! info ""
    **Inherits:** [`TauPaneOverlayConfig`](pane_overlay_config.md)

Configures a [`LINE`](tau_plot.md#paneoverlaytype) overlay rendered inside a pane.

## Description

`TauLineConfig` is the concrete [`TauPaneOverlayConfig`](pane_overlay_config.md) subclass for line overlays. Place one instance in [`TauPaneConfig.overlays`](pane_config.md#overlays) to draw one curve per series in that pane, through the samples of the series in X order. [`overlay_type`](pane_overlay_config.md#overlay_type) is set to [`LINE`](tau_plot.md#paneoverlaytype) at construction.

The [`mode`](#mode) controls how the curves of the series relate to one another:

- [`INDEPENDENT`](#linemode) draws each series straight from its own values.
- [`STACKED`](#linemode) draws each series on top of the ones before it, so its curve carries the running total at every X rather than its own value.

The **interpolation mode** decides what is drawn between two consecutive samples. It is a [per-series cycle](style.md#cycles) rather than a single setting, so a raw stepped series can sit under a smoothed trend in one overlay:

- [`LINEAR`](#interpolationmode) draws a straight segment.
- [`STEP_BEFORE`](#interpolationmode), [`STEP_AFTER`](#interpolationmode), and [`STEP_MIDDLE`](#interpolationmode) draw a staircase. They differ by where the vertical jump happens.
- [`SMOOTH_MONOTONE`](#interpolationmode) draws a monotone cubic curve through the samples.

The **gap policy** decides what the curve does at a sample the plot cannot place. A sample is invalid when its X or Y value is `NaN` or infinite. A sample is also invalid when the scale of its axis cannot take the value, as a [`LOGARITHMIC`](axis_config.md#scale-enum) axis cannot take a value at or below zero. [`SKIP`](#gappolicy) cuts the curve at that sample, so the sample before it and the sample after it stay unconnected. [`BRIDGE`](#gappolicy) drops the sample and draws one segment from the sample before it to the sample after it.

[`mode`](#mode) affects the Y domain, and [`stacked_normalization`](#stacked_normalization) and [`stacked_negative_policy`](#stacked_negative_policy) affect it while [`mode`](#mode) is [`STACKED`](#linemode). Changing any of the three triggers a full layout recomputation on the next refresh. Every other property on this class is visual-only and triggers a redraw alone.

Line width, dash pattern, hover emphasis, and the area painted around each curve are controlled by [`style`](#style). Per-sample color and alpha overrides are supplied through [`line_visual_callbacks`](#line_visual_callbacks) or through [`LineVisualAttributes`](line_visual_attributes.md) on the series binding. See [`TauPaneOverlayConfig`](pane_overlay_config.md#per-sample-overrides) for how the two mechanisms resolve against each other and against the style.

After [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) succeeds, the plot holds a reference to this instance. Mutating a property at runtime is supported, but requires calling [`TauPlot.queue_refresh()`](tau_plot.md#queue_refresh) to apply the change.

### Example

```gdscript
var line_overlay := TauLineConfig.new()
line_overlay.gap_policy = TauLineConfig.GapPolicy.BRIDGE

# The raw series steps, the trend series is smoothed.
line_overlay.interpolation_modes = [
	TauLineConfig.InterpolationMode.STEP_AFTER,
	TauLineConfig.InterpolationMode.SMOOTH_MONOTONE,
]

var pane := TauPaneConfig.new()
pane.y_left_axis = TauAxisConfig.new()
pane.overlays = [line_overlay]
```

### Notes

1. **Two stacked overlays on one Y axis must agree.** When a [`STACKED`](#linemode) line overlay and a [`STACKED`](bar_config.md#barmode) bar overlay land on the same Y axis of the same pane, both feed the range of that axis. Their [`stacked_normalization`](#stacked_normalization) values must be equal, and their [`stacked_negative_policy`](#stacked_negative_policy) values must be equal. A mismatch is a validation error and [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) aborts. [`TauBarConfig`](bar_config.md) rejects [`SIGNED_SUM`](tau_plot.md#stackednegativepolicy) outright, so a pane pairing the two stacked overlays uses [`DIVERGING`](tau_plot.md#stackednegativepolicy) or [`SKIP_NEGATIVES`](tau_plot.md#stackednegativepolicy).

2. **`SMOOTH_MONOTONE` needs a monotonic X sequence.** A run whose X values are not monotonic has no monotone curve to fit. The run falls back to straight segments and the plot pushes a warning once per overlay. [`LINEAR`](#interpolationmode) is the mode for data with a non-monotonic X parameter.

3. **A series that paints nothing reports no hover.** A series whose resolved [`TauLineStyle.line_widths_px`](line_style.md#line_widths_px) entry is `0` and whose [`TauLineFill`](line_fill.md) is [`NONE`](line_fill.md#fillmode) is skipped entirely, so it answers no hover regardless of [`hoverable`](pane_overlay_config.md#hoverable). A series with a fill and no stroke still reports hover on its samples.

4. **Stacked hits carry two values.** In [`STACKED`](#linemode) mode, [`SampleHit.y_plotted_value`](sample_hit.md#y_plotted_value) holds the value the curve was drawn at, which is the running total, and [`SampleHit.y_raw_value`](sample_hit.md#y_raw_value) holds the value stored in the [`Dataset`](dataset.md). [`LineVisualCallbacks`](line_visual_callbacks.md) always receives the stored value, never the running total.

## Enums

### `LineMode`

Controls how the curves of the series in the overlay relate to one another.

| Value | Meaning |
|---|---|
| `INDEPENDENT` | Each series is drawn on its own, straight from its values. Curves may cross and overlap. |
| `STACKED` | Each series is drawn on top of the ones before it, so its curve carries the running total at every X. The series are stacked in dataset order. |

---

### `InterpolationMode`

Controls what is drawn between two consecutive samples of one series.

| Value | Meaning |
|---|---|
| `LINEAR` | A straight segment between the two samples. |
| `STEP_BEFORE` | A staircase whose vertical jump happens as early as possible, at the X position of the previous sample. |
| `STEP_AFTER` | A staircase whose vertical jump happens as late as possible, at the X position of the next sample. |
| `STEP_MIDDLE` | A staircase whose vertical jump happens at the pixel midpoint between the two X positions. |
| `SMOOTH_MONOTONE` | A piecewise cubic curve through the samples, using Fritsch-Carlson tangents. It passes through every sample exactly and preserves local monotonicity, so it adds no overshoot and no extremum between two samples. |

---

### `GapPolicy`

Controls what the curve does at a sample the plot cannot place.

| Value | Meaning |
|---|---|
| `SKIP` | Cuts the curve at the invalid sample. The sample before it and the sample after it stay unconnected, and each side of the cut is drawn as its own curve. |
| `BRIDGE` | Drops the invalid sample and draws one segment from the sample before it to the sample after it, so the curve stays continuous. |

## Constructor

### `new()`

```gdscript
TauLineConfig.new() -> TauLineConfig
```

Creates a new `TauLineConfig` with all properties set to their built-in defaults and [`overlay_type`](pane_overlay_config.md#overlay_type) set to [`LINE`](tau_plot.md#paneoverlaytype). The instance is ready to place in [`TauPaneConfig.overlays`](pane_config.md#overlays).

## Properties

### mode

`mode`: [`LineMode`](#linemode)

How the curves of the series in the overlay relate to one another. Default is [`INDEPENDENT`](#linemode).

[`STACKED`](#linemode) adds up the values of the series at each X position. It therefore requires a [`SHARED_X`](dataset.md#mode) [`Dataset`](dataset.md), requires every series bound to this overlay to use the same Y axis, and rejects a [`LOGARITHMIC`](axis_config.md#scale-enum) Y axis, on which a running total is not meaningful. Each of the three is a validation error and [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) aborts. [`INDEPENDENT`](#linemode) has no dataset or axis constraint.

Changing this property triggers a full layout recomputation on the next refresh, since stacking changes the Y domain.

---

### interpolation_modes

`interpolation_modes`: `Array[InterpolationMode]`

Cycle holding what is drawn between two consecutive samples of each series. Default is `[LINEAR]`.

Read as a cycle: series `i` uses entry `i % size`, where `i` is the series index in the [`Dataset`](dataset.md). An empty array falls back to [`LINEAR`](#interpolationmode) for every series. See [`TauStyle`](style.md#cycles).

This property is visual-only.

---

### gap_policy

`gap_policy`: [`GapPolicy`](#gappolicy)

What the curve does at a sample the plot cannot place, for every series in the overlay. Default is [`SKIP`](#gappolicy).

A sample is invalid when its X or Y value is `NaN` or infinite. It is also invalid when the scale of its axis cannot take the value, as a [`LOGARITHMIC`](axis_config.md#scale-enum) axis cannot take a value at or below zero.

This property is visual-only.

---

### stacked_normalization

`stacked_normalization`: [`StackedNormalization`](tau_plot.md#stackednormalization)

What each stack is scaled to. Default is [`NONE`](tau_plot.md#stackednormalization).

Only used when [`mode`](#mode) is [`STACKED`](#linemode), and ignored otherwise. [`FRACTION`](tau_plot.md#stackednormalization) and [`PERCENT`](tau_plot.md#stackednormalization) pin the Y range to the normalized total instead of deriving it from the data. See [note 1](#notes) for the constraint against a stacked bar overlay on the same axis.

Changing this property while [`mode`](#mode) is [`STACKED`](#linemode) triggers a full layout recomputation on the next refresh, since normalization changes the Y domain.

---

### stacked_negative_policy

`stacked_negative_policy`: [`StackedNegativePolicy`](tau_plot.md#stackednegativepolicy)

How a negative value enters a stack. Default is [`SIGNED_SUM`](tau_plot.md#stackednegativepolicy), which adds the negative value to the running total, so the curve of that series dips below the curve under it. This is the streamgraph shape.

Only used when [`mode`](#mode) is [`STACKED`](#linemode), and ignored otherwise. The policy decides how negative values are treated, which changes the values the curves are drawn at and therefore the Y domain as well. See [note 1](#notes) for the constraint against a stacked bar overlay on the same axis.

Changing this property while [`mode`](#mode) is [`STACKED`](#linemode) triggers a full layout recomputation on the next refresh.

---

### hover_max_distance_px

`hover_max_distance_px`: `int`

The maximum distance in pixels between the cursor and a sample for that sample to count as a hit. Default is `10`.

How the distance is measured depends on the active [hover mode](hover_config.md#hovermode) and the [X axis type](axis_config.md#type-enum):

- In [`NEAREST`](hover_config.md#hovermode) mode, the distance is the 2D Euclidean distance from the cursor to the sample. A sample farther than this value is dropped, and the nearest of the remaining samples is the hit.
- In [`X_ALIGNED`](hover_config.md#hovermode) mode on a continuous X axis, only the horizontal distance counts. A sample whose X screen position is farther than this value from the target X is dropped. For the samples that remain, the 2D Euclidean distance to the cursor is compared to the same value to set [`SampleHit.contains_pointer`](sample_hit.md#contains_pointer).
- In [`X_ALIGNED`](hover_config.md#hovermode) mode on a categorical X axis, no sample is dropped. Every sample at the matching category is reported, and the value only sets [`SampleHit.contains_pointer`](sample_hit.md#contains_pointer), which drives the visual hover emphasis.

This property is visual-only.

---

### style

`style`: [`TauLineStyle`](line_style.md)

The visual style applied to the curves in this overlay: line width per state, dash pattern, and the per-series area fill. Default is a freshly constructed [`TauLineStyle`](line_style.md) with all built-in defaults.

Never `null`. Modify properties directly on the instance. Any property left unassigned on this instance can still be set by the active Godot theme. Multiple `TauLineConfig` instances can share the same [`TauLineStyle`](line_style.md) resource.

---

### line_visual_callbacks

`line_visual_callbacks`: [`LineVisualCallbacks`](line_visual_callbacks.md)

Typed accessor for the per-sample visual callbacks of this overlay. Default is `null`.

Reads and writes the inherited [`TauPaneOverlayConfig.visual_callbacks`](pane_overlay_config.md#visual_callbacks) cast to [`LineVisualCallbacks`](line_visual_callbacks.md). Assigning an instance of another type through the base property and reading it back here returns `null`, while [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) reports it as a validation error and aborts.

`line_visual_callbacks` is not serializable. The property is not exported and cannot be saved in a `.tres` resource file. Assign it at runtime only.

## Related Classes

* [`TauPlot`](tau_plot.md) The plot node. Consumes `TauLineConfig` during layout and rendering.
* [`TauPaneOverlayConfig`](pane_overlay_config.md) Base class. Defines [`overlay_type`](pane_overlay_config.md#overlay_type), [`z_order`](pane_overlay_config.md#z_order), [`hoverable`](pane_overlay_config.md#hoverable), and [`visual_callbacks`](pane_overlay_config.md#visual_callbacks).
* [`TauPaneConfig`](pane_config.md) Holds the overlay in its [`overlays`](pane_config.md#overlays) array.
* [`TauAxisConfig`](axis_config.md) Configures the axes the curves are mapped onto, including the scale that decides which samples are valid.
* [`TauLineStyle`](line_style.md) Controls visual appearance. Owned by this config via [`style`](#style).
* [`TauLineFill`](line_fill.md) Per-series area fill, held by [`TauLineStyle.fills`](line_style.md#fills).
* [`TauStyle`](style.md) Base class of the style resources. Defines the cascade and the cycle indexing [`interpolation_modes`](#interpolation_modes) follows.
* [`LineVisualCallbacks`](line_visual_callbacks.md) Supplies per-sample color and alpha overrides from callbacks.
* [`LineVisualAttributes`](line_visual_attributes.md) Supplies per-sample color and alpha overrides from pre-built buffers. Takes priority over [`LineVisualCallbacks`](line_visual_callbacks.md).
* [`TauXYSeriesBinding`](xy_series_binding.md) Maps a series of the dataset to this overlay and holds its [`visual_attributes`](xy_series_binding.md#visual_attributes).
* [`TauXYStyle`](xy_style.md) Supplies the per-series colors the curves and fills fall back to.
* [`Dataset`](dataset.md) The data model. Its series index drives the [`interpolation_modes`](#interpolation_modes) cycle.
* [`TauHoverConfig`](hover_config.md) Holds the hover mode [`hover_max_distance_px`](#hover_max_distance_px) is interpreted under.
* [`SampleHit`](sample_hit.md) One reported hit, carrying the distance and the flag [`hover_max_distance_px`](#hover_max_distance_px) sets.
* [`TauBarConfig`](bar_config.md) Sibling overlay configuration for bar overlays. Shares the stacking constraint in [note 1](#notes).
* [`TauScatterConfig`](scatter_config.md) Sibling overlay configuration for scatter overlays.