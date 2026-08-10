# TauPlot

!!! info ""
    **Inherits:** `PanelContainer`  

Root node for creating and displaying plots. 

## Description

`TauPlot` is the root node for creating and displaying plots. Add it to your scene, then call a plot-type method to build and display a plot.

Before a plot is created, all provided inputs are validated. This helps catch misconfiguration early and report it through user-friendly warnings or errors.

Once created, a plot remains live. It listens to the dataset and refreshes automatically when the data changes. Configuration and style objects can also be modified at runtime, but require [`queue_refresh()`](#queue_refresh) or [`refresh_now()`](#refresh_now) to apply. Refreshes are incremental and avoid rebuilding the whole plot when possible.

All plot types share the same high-level container behavior and optional interaction systems:

- a **legend**, enabled by default, whose visibility is controlled through [`legend_enabled`](#legend_enabled) and whose placement, flow direction, and appearance are controlled through [`legend_config`](#legend_config)
- a **hover inspection** system, disabled by default, which can provide tooltips, highlighting, and sample interaction signals

When [`hover_enabled`](#hover_enabled) is `true`, the plot can detect hovered samples, display tooltips, highlight data, and emit interaction signals. Use [`hover_config`](#hover_config) to configure the built-in behavior, or disable the built-in tooltip and drive your own UI from the interaction signals:

- [`sample_hovered`](#sample_hovered)
- [`sample_hover_exited`](#sample_hover_exited)
- [`sample_clicked`](#sample_clicked)
- [`sample_click_dismissed`](#sample_click_dismissed)

### XY plots

[`plot_xy()`](#plot_xy) builds an XY plot from three objects:

- a [`Dataset`](dataset.md) containing the data
- a [`TauXYConfig`](xy_config.md) describing the plot structure
- an array of [`TauXYSeriesBinding`](xy_series_binding.md) that maps series to panes, overlays, and axes

The [`Dataset`](dataset.md) stores the actual samples. The [`TauXYConfig`](xy_config.md) defines how the plot is laid out. The [`TauXYSeriesBinding`](xy_series_binding.md) objects connect both by specifying where and how each dataset series should be rendered.

An XY plot is organized around one shared **X axis**. This axis spans the whole plot and is configured through [`TauXYConfig.x_axis_id`](xy_config.md#x_axis_id). Its position determines how panes are arranged:

- when the X axis is on the top or bottom edge, panes are stacked vertically
- when the X axis is on the left or right edge, panes are stacked horizontally

A plot may contain one or more **panes**. Most XY plots need only one pane, but multiple panes are useful when different series should not share the same Y scale, such as a price series above a volume series.

Each pane contains one or more **overlays**, which are the visual layers that render the data, such as bars or scatter points. A pane also manages its own Y axes independently from the other panes.

Each pane can expose up to two **Y axes**, placed on the two edges orthogonal to the X axis. For example, if the X axis is on the bottom, the pane may use a left Y axis, a right Y axis, or both. This allows series with very different value ranges to be displayed in the same pane without sharing the same scale.

A series can be bound once or multiple times depending on the intended visualization. See [`TauXYSeriesBinding`](xy_series_binding.md) for the supported binding rules.

By default, **domains** and **ticks** are computed automatically. Each axis scans the data, applies configurable padding, and selects readable tick positions that fit without overlap. When automatic bounds are not desired, [`TauAxisConfig.range_override_enabled`](axis_config.md#range_override_enabled) can be used to force a fixed range.

After [`plot_xy()`](#plot_xy) succeeds, the plot listens to the dataset and refreshes automatically whenever the data changes. The configuration and style objects can also be modified at runtime. In that case, call [`queue_refresh()`](#queue_refresh) to apply the changes.

### Hover inspection

When [`hover_enabled`](#hover_enabled) is `true`, the plot can detect hovered samples, show tooltips, and emit interaction signals.

Use [`hover_config`](#hover_config) to customize the built-in behavior, or leave the tooltip disabled and drive your own UI using:

- [`sample_hovered`](#sample_hovered)
- [`sample_hover_exited`](#sample_hover_exited)
- [`sample_clicked`](#sample_clicked)
- [`sample_click_dismissed`](#sample_click_dismissed)

### Quick usage

1. Add a `TauPlot` node to your scene.
2. Build a [`Dataset`](dataset.md).
3. Build an [`TauXYConfig`](xy_config.md).
4. Create one [`TauXYSeriesBinding`](xy_series_binding.md) per plotted series.
5. Call [`plot_xy()`](#plot_xy).

### Example

```gdscript
	var dataset := TauPlot.Dataset.make_shared_x_categorical(
		PackedStringArray(["Revenue", "Costs"]),
		PackedStringArray(["Q1", "Q2", "Q3", "Q4"]),
		[
			PackedFloat64Array([120.0, 135.0, 148.0, 160.0]),
			PackedFloat64Array([90.0, 95.0, 100.0, 108.0]),
		]
	)

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL

	var y_axis := TauAxisConfig.new()
	y_axis.title = "EUR"

	var bar_overlay_config := TauBarConfig.new()

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [bar_overlay_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var b0 := TauXYSeriesBinding.new()
	b0.series_id = dataset.get_series_id_by_index(0)
	b0.pane_index = 0
	b0.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	b0.y_axis_id = TauPlot.AxisId.LEFT

	var b1 := TauXYSeriesBinding.new()
	b1.series_id = dataset.get_series_id_by_index(1)
	b1.pane_index = 0
	b1.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	b1.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [b0, b1]

	$MyPlot.title = "Quick Start Example"
	$MyPlot.plot_xy(dataset, config, bindings)
```

### Common workflows

**Update the data**  
Mutate the [`Dataset`](dataset.md). The plot refreshes automatically when the dataset emits [`changed`](dataset.md#changed).

**Change plot configuration at runtime**  
Mutate the objects passed to [`plot_xy()`](#plot_xy), then call [`queue_refresh()`](#queue_refresh).

**Replace the current plot**  
Call [`plot_xy()`](#plot_xy) again. The current plot is cleared automatically before the new one is built.

**Reset the plot**  
Call [`reset()`](#reset).

### Notes

1. **`plot_xy()` replaces the active plot.** Calling it while a plot is already displayed tears down the current plot before building the new one. The previous dataset is disconnected automatically.

2. **Validation errors abort without modifying the current plot.** If validation finds errors, [`plot_xy()`](#plot_xy) logs them and returns, leaving the existing plot in place. Validation warnings are logged but do not abort.

## TauPlot Namespace

`TauPlot` is registered as a global class, so it can be referenced directly anywhere in GDScript.

Most supporting types in the addon are intentionally not registered as global classes to avoid cluttering the global class namespace. Instead, they are exposed as constants on `TauPlot`. This makes the most common `TauPlot` types available from a single access point without requiring separate `preload()` calls.

Reference them as `TauPlot.ClassName`, for example `TauPlot.Dataset.new()` or `TauPlot.ColorBuffer.new()`.

The types listed below are available through this namespace.

* [`Dataset`](dataset.md) Holds all X and Y sample data for one or more named series and notifies the plot of every change.
* [`DatasetChange`](dataset_change.md) Describes one change applied to a [`Dataset`](dataset.md), carried by [`changed`](dataset.md#changed).
* [`VisualAttributes`](visual_attributes.md) Abstract base class for data-oriented per-sample style override buffers.
* [`BarVisualAttributes`](bar_visual_attributes.md) Per-sample style override buffers for [`BAR`](#paneoverlaytype) overlays.
* [`ScatterVisualAttributes`](scatter_visual_attributes.md) Per-sample style override buffers for [`SCATTER`](#paneoverlaytype) overlays.
* [`LineVisualAttributes`](line_visual_attributes.md) Per-sample style override buffers for [`LINE`](#paneoverlaytype) overlays.
* [`VisualCallbacks`](visual_callbacks.md) Abstract base class for callback-driven per-sample style overrides.
* [`BarVisualCallbacks`](bar_visual_callbacks.md) Callback-driven per-sample style overrides for [`BAR`](#paneoverlaytype) overlays.
* [`ScatterVisualCallbacks`](scatter_visual_callbacks.md) Callback-driven per-sample style overrides for [`SCATTER`](#paneoverlaytype) overlays.
* [`LineVisualCallbacks`](line_visual_callbacks.md) Callback-driven per-sample style overrides for [`LINE`](#paneoverlaytype) overlays.
* [`SampleHit`](sample_hit.md) Read-only description of one sample detected near the cursor during hover hit testing.
* [`ColorBuffer`](color_buffer.md) Ring buffer storing `Color` values with a fixed capacity.
* [`Float32Buffer`](float32_buffer.md) Ring buffer storing `float` values (32-bit) with a fixed capacity.
* [`Float64Buffer`](float64_buffer.md) Ring buffer storing `float` values (64-bit) with a fixed capacity.
* [`Int32Buffer`](int32_buffer.md) Ring buffer storing `int` values (32-bit) with a fixed capacity.
* [`StringBuffer`](string_buffer.md) Ring buffer storing `String` values with a fixed capacity.

The enums under [Enums](#enums) are exposed on the same namespace: [`AxisId`](#axisid), [`PaneOverlayType`](#paneoverlaytype), [`StackedNormalization`](#stackednormalization), and [`StackedNegativePolicy`](#stackednegativepolicy).

## Enums

### `AxisId`

Identifies an axis by the edge position it occupies on the plot.

| Value | Meaning |
|---|---|
| `BOTTOM` | The bottom edge position. |
| `TOP` | The top edge position. |
| `LEFT` | The left edge position. |
| `RIGHT` | The right edge position. |

---

### `PaneOverlayType`

Identifies the visual layer type used to render series data inside a pane.

| Value | Meaning |
|---|---|
| `BAR` | Bar overlay. Renders each sample as a bar originating from zero. |
| `SCATTER` | Scatter overlay. Renders each sample as a marker at its data position. |
| `LINE` | Line overlay. Renders each series as one curve through its sample positions, with an optional area fill. |

---

### `StackedNormalization`

Sets what each stack of a stacking overlay is scaled to.

| Value | Meaning |
|---|---|
| `NONE` | Stacks the raw values. The top of each stack is their sum. |
| `FRACTION` | Scales each stack to `1.0`. Each series carries its share of the stack. |
| `PERCENT` | Scales each stack to `100.0`. The same share expressed as a percentage. |

---

### `StackedNegativePolicy`

Sets how a negative value enters a stack.

| Value | Meaning |
|---|---|
| `DIVERGING` | Positive values stack upward from zero and negative values stack downward from zero. Each X position carries two independent cumulatives. |
| `SIGNED_SUM` | Negative values enter the cumulative signed, so a negative sample dips the stack below the layer under it. A stacking [`BAR`](#paneoverlaytype) overlay cannot draw that dip without overlapping rectangles, and [`plot_xy()`](#plot_xy) reports a validation error when one declares it. |
| `SKIP_NEGATIVES` | Negative values are dropped from the cumulative. The sample stacks as if its value were zero. |

## Signals

### `sample_hovered()`

```gdscript
signal sample_hovered(hits: Array[SampleHit])
```

Emitted when the mouse moves over one or more samples. `hits` contains one [`SampleHit`](sample_hit.md) per detected sample. In [`NEAREST`](hover_config.md#hovermode) mode the array contains one entry. In [`X_ALIGNED`](hover_config.md#hovermode) mode it may contain one entry per series at the nearest X position. For [`PER_SERIES_X`](dataset.md#mode) datasets, only series that have a data point at the globally nearest X value are included, so the array often contains a single entry. Requires [`hover_enabled`](#hover_enabled) to be `true`.

---

### `sample_hover_exited()`

```gdscript
signal sample_hover_exited()
```

Emitted when the mouse leaves all sample hit zones. Requires [`hover_enabled`](#hover_enabled) to be `true`.

---

### `sample_clicked()`

```gdscript
signal sample_clicked(hits: Array[SampleHit])
```

Emitted on a mouse click over one or more samples. `hits` follows the same content rules as [`sample_hovered`](#sample_hovered). Requires [`hover_enabled`](#hover_enabled) to be `true`.

---

### `sample_click_dismissed()`

```gdscript
signal sample_click_dismissed()
```

Emitted when a pinned tooltip is dismissed by clicking on empty space or by pressing Escape. Requires [`hover_enabled`](#hover_enabled) to be `true`.

## Properties

### title

`title`: `String`

Sets the title displayed above the plot. Supports BBCode. Defaults to `""`, which hides the title. Updates immediately when the node is inside the scene tree.

---

### hover_enabled

`hover_enabled`: `bool`

Master switch for the hover inspection system. When `false`, no hit testing runs, no hover signals fire, and no tooltip, crosshair, or highlight renders. When `true`, the system activates using the settings in [`hover_config`](#hover_config). Defaults to `true`. Safe to set after [`plot_xy()`](#plot_xy).

---

### hover_config

`hover_config`: [`TauHoverConfig`](hover_config.md)

Configuration for the hover inspection system. Controls hover mode, tooltip, crosshair, highlight, and formatting callbacks. If `null`, built-in defaults apply for all settings. Defaults to `null`. Safe to set after [`plot_xy()`](#plot_xy).

---

### legend_enabled

`legend_enabled`: `bool`

Controls legend visibility. When `true`, the legend renders using the settings in [`legend_config`](#legend_config). When `false`, the legend is hidden. Defaults to `true`.

---

### legend_config

`legend_config`: [`TauLegendConfig`](legend_config.md)

Configuration for the legend system. Controls position, flow direction, and visual style. If `null`, built-in defaults apply for all settings. Defaults to `null`. Safe to set after [`plot_xy()`](#plot_xy).

## Methods

### Plot lifecycle

#### plot_xy()

```gdscript
plot_xy(p_dataset: Dataset, p_xy_config: TauXYConfig, p_series_bindings: Array[TauXYSeriesBinding]) -> void
```

Builds and displays an XY plot.

Validates all inputs before making any change (see [Note 2](#notes)). On success, tears down any active plot, builds renderers, axes, panes, the legend, and the hover controller, subscribes to `p_dataset.`[`changed`](dataset.md#changed), and schedules the first render. The plot keeps references to the provided parameters. Mutating them after plotting is supported, but requires [`queue_refresh()`](#queue_refresh) or [`refresh_now()`](#refresh_now) to apply the changes.

**Parameters**

* `p_dataset: Dataset` The data model. The plot holds a reference and subscribes to its [`changed`](dataset.md#changed) signal for the lifetime of this plot. Must not be `null`.
* `p_xy_config: TauXYConfig` Defines the X axis, pane layout, overlay configurations, and visual settings. Must not be `null`.
* `p_series_bindings: Array[TauXYSeriesBinding]` One entry per series-to-pane mapping. Each entry specifies a [`series_id`](xy_series_binding.md#series_id), a [`pane_index`](xy_series_binding.md#pane_index), an [`overlay_type`](xy_series_binding.md#overlay_type), and a [`y_axis_id`](xy_series_binding.md#y_axis_id). Must not be `null`.

---

#### reset()

```gdscript
reset() -> void
```

Destroys the active plot and resets the node to an empty state.

Frees all renderer nodes, disconnects dataset and style signals, and hides the title. Safe to call when no plot is active.

---

#### queue_refresh()

```gdscript
queue_refresh() -> void
```

Schedules a render update for the next frame.

If a refresh is already pending, does nothing. Call this after mutating configuration or style properties on the objects passed to [`plot_xy()`](#plot_xy) to apply the changes.

---

#### refresh_now()

```gdscript
refresh_now() -> void
```

Forces an immediate refresh in the current frame. Use this only when the plot needs to be up to date synchronously. For most UI-driven updates, prefer [`queue_refresh()`](#queue_refresh), since theme and layout changes may settle on the next frame.

## Related Classes

* [`Dataset`](dataset.md) The data model passed to [`plot_xy()`](#plot_xy). The plot subscribes to its [`changed`](dataset.md#changed) signal.
* [`TauXYConfig`](xy_config.md) Defines the XY plot configuration used by [`plot_xy()`](#plot_xy).
* [`TauXYSeriesBinding`](xy_series_binding.md) Maps a dataset series to a pane, overlay, and Y axis for [`plot_xy()`](#plot_xy).
* [`TauLegendConfig`](legend_config.md) Configures the legend system, assigned to [`legend_config`](#legend_config).
* [`TauHoverConfig`](hover_config.md) Configures the hover inspection system, assigned to [`hover_config`](#hover_config).
* [`SampleHit`](sample_hit.md) Carried by [`sample_hovered`](#sample_hovered) and [`sample_clicked`](#sample_clicked) to describe a sample hovered by the mouse.
* [`TauLegendStyle`](legend_style.md) Controls visual appearance of the legend, owned by [`TauLegendConfig.style`](legend_config.md#style).
* [`TauPaneConfig`](pane_config.md) One entry in [`TauXYConfig.panes`](xy_config.md#panes), defining a pane's axes and overlay configurations.
* [`TauAxisConfig`](axis_config.md) Configures an individual axis: type, scale, domain, ticks, and title.
* [`TauBarConfig`](bar_config.md) Bar overlay configuration placed inside a [`TauPaneConfig`](pane_config.md).
* [`TauScatterConfig`](scatter_config.md) Scatter overlay configuration placed inside a [`TauPaneConfig`](pane_config.md).
* [`TauLineConfig`](line_config.md) Line overlay configuration placed inside a [`TauPaneConfig`](pane_config.md).