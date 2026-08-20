# SampleHit

!!! info ""
    **Inherits:** `RefCounted`  
    **Namespace:** [`TauPlot`](tau_plot.md)

Read-only data object describing one sample detected near the cursor during hover hit testing.

## Description

`SampleHit` carries the identity, values, and screen position of one sample found near the cursor. The plot builds every instance, and user code only reads them.

Arrays of `SampleHit` objects are delivered through the [`TauPlot.sample_hovered`](tau_plot.md#sample_hovered) and [`TauPlot.sample_clicked`](tau_plot.md#sample_clicked) signals, and are also passed to the [`TauHoverConfig.format_tooltip_text`](hover_config.md#format_tooltip_text) and [`TauHoverConfig.create_tooltip_control`](hover_config.md#create_tooltip_control) callbacks. How many hits an array contains and which samples qualify depend on the active hover mode. See [`TauHoverConfig`](hover_config.md) for a full description of the hover inspection system.

The first hit of an array is the sample the cursor is on. When the cursor is on no sample, it is the closest one. The plot uses it to place the tooltip.

## Properties

### series_id

`series_id`: `int`

The stable series ID of the hit series, as assigned by the [`Dataset`](dataset.md).

---

### series_name

`series_name`: `String`

The human-readable name of the hit series, as stored in the [`Dataset`](dataset.md).

---

### sample_index

`sample_index`: `int`

The logical index of the hit sample within its series.

---

### x_value

`x_value`: `Variant`

The X value of the hit sample. Holds a `float` when the X axis is [`CONTINUOUS`](axis_config.md#type-enum), or a `String` when it is [`CATEGORICAL`](axis_config.md#type-enum).

In [`X_ALIGNED`](hover_config.md#hovermode) mode, two hits of the same array can carry different X values. This happens when the overlays of the pane do not use the same X values. Each overlay picks the X position closest to the hovered one among the positions where it has samples, so two overlays can land on different values.

---

### y_plotted_value

`y_plotted_value`: `float`

The Y position the sample is drawn at, in axis units.

On a [`STACKED`](bar_config.md#barmode) bar overlay or a [`STACKED`](line_config.md#linemode) line overlay this is the cumulative total of the stack up to and including this series, rescaled when [`FRACTION`](tau_plot.md#stackednormalization) or [`PERCENT`](tau_plot.md#stackednormalization) normalization is active. In every other case it equals [`y_raw_value`](#y_raw_value).

---

### y_raw_value

`y_raw_value`: `float`

The Y value the [`Dataset`](dataset.md) holds for the sample, before stacking, normalization, and accumulation.

This is the value the built-in tooltip formatter renders, and the one to report when a tooltip has to answer what this series measured at this X. [`y_plotted_value`](#y_plotted_value) answers where the sample sits on the axis instead.

---

### screen_position

`screen_position`: `Vector2`

The pixel position of the hit sample in the plot's local coordinate space. For a [`BAR`](tau_plot.md#paneoverlaytype) overlay this is the center of the bar tip, the edge the bar grows toward. For a [`SCATTER`](tau_plot.md#paneoverlaytype) overlay this is the center of the marker. For a [`LINE`](tau_plot.md#paneoverlaytype) overlay this is the sample position on the curve, never an interpolated point between two samples.

---

### pane_index

`pane_index`: `int`

The zero-based index of the pane the hit sample belongs to, matching its position in [`TauXYConfig.panes`](xy_config.md#panes).

---

### overlay_type

`overlay_type`: [`PaneOverlayType`](tau_plot.md#paneoverlaytype)

The overlay type that produced this hit.

---

### distance_px

`distance_px`: `float`

The pixel distance from the cursor to [`screen_position`](#screen_position). Useful for a custom proximity threshold applied when handling [`sample_hovered`](tau_plot.md#sample_hovered) or [`sample_clicked`](tau_plot.md#sample_clicked).

---

### contains_pointer

`contains_pointer`: `bool`

`true` when the cursor sits inside the hit zone of the sample.

A [`BAR`](tau_plot.md#paneoverlaytype) overlay uses the painted bar rectangle. A [`SCATTER`](tau_plot.md#paneoverlaytype) or [`LINE`](tau_plot.md#paneoverlaytype) overlay has no area to fall inside, so it uses a disc of [`TauScatterConfig.hover_max_distance_px`](scatter_config.md#hover_max_distance_px) or [`TauLineConfig.hover_max_distance_px`](line_config.md#hover_max_distance_px) pixels around [`screen_position`](#screen_position). In [`NEAREST`](hover_config.md#hovermode) mode the flag is always `true`, because that mode discards every sample that fails the same test.

## Related Classes

* [`TauPlot`](tau_plot.md) Emits [`sample_hovered`](tau_plot.md#sample_hovered) and [`sample_clicked`](tau_plot.md#sample_clicked) carrying arrays of `SampleHit`.
* [`TauHoverConfig`](hover_config.md) Configures the hover inspection system that produces `SampleHit` instances. Callbacks [`format_tooltip_text`](hover_config.md#format_tooltip_text) and [`create_tooltip_control`](hover_config.md#create_tooltip_control) receive these arrays.
* [`Dataset`](dataset.md) Source of the series data that [`series_id`](#series_id), [`series_name`](#series_name), [`sample_index`](#sample_index), and [`y_raw_value`](#y_raw_value) refer back to.
* [`TauBarConfig`](bar_config.md) Bar overlay configuration. Its [`mode`](bar_config.md#mode) decides whether [`y_plotted_value`](#y_plotted_value) differs from [`y_raw_value`](#y_raw_value).
* [`TauScatterConfig`](scatter_config.md) Scatter overlay configuration. Holds the [`hover_max_distance_px`](scatter_config.md#hover_max_distance_px) threshold behind [`contains_pointer`](#contains_pointer).
* [`TauLineConfig`](line_config.md) Line overlay configuration. Holds the [`hover_max_distance_px`](line_config.md#hover_max_distance_px) threshold behind [`contains_pointer`](#contains_pointer), and the [`mode`](line_config.md#mode) that makes [`y_plotted_value`](#y_plotted_value) cumulative.
* [`TauXYConfig`](xy_config.md) Holds the [`panes`](xy_config.md#panes) array that [`pane_index`](#pane_index) indexes.