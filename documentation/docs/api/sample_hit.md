# SampleHit

!!! info ""
    **Inherits:** `RefCounted`  
    **Namespace:** [`TauPlot`](tau_plot.md)

Read-only data object describing one sample detected near the cursor during hover hit testing.

## Description

`SampleHit` is produced by the hover inspection system and carries the identity, values, and screen position of one sample that was found near the cursor.

Arrays of `SampleHit` objects are delivered through the [`TauPlot.sample_hovered`](tau_plot.md#sample_hovered) and [`TauPlot.sample_clicked`](tau_plot.md#sample_clicked) signals, and are also passed to the [`TauHoverConfig.format_tooltip_text`](hover_config.md#format_tooltip_text) and [`TauHoverConfig.create_tooltip_control`](hover_config.md#create_tooltip_control) callbacks. How many hits an array contains and which samples qualify depend on the active hover mode. See [`TauHoverConfig`](hover_config.md) for a full description of the hover inspection system.

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

The X value of the hit sample. Holds a `float` when the X axis is [`CONTINUOUS`](axis_config.md#type), or a `String` when it is [`CATEGORICAL`](axis_config.md#type).

---

### y_value

`y_value`: `float`

The Y value of the hit sample.

---

### screen_position

`screen_position`: `Vector2`

The pixel position of the hit sample in the plot's local coordinate space. For bar overlays this is the top-center of the bar. For scatter overlays this is the center of the marker.

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

The pixel distance from the cursor to [`screen_position`](#screen_position). Useful for implementing a custom proximity threshold when handling [`sample_hovered`](tau_plot.md#sample_hovered) or [`sample_clicked`](tau_plot.md#sample_clicked).

---

### contains_pointer

`contains_pointer`: `bool`

`true` when the cursor falls inside the visual bounds of the sample: the bar rectangle for bar overlays, the marker radius for scatter overlays.

## Related Classes

* [`TauPlot`](tau_plot.md) Emits [`sample_hovered`](tau_plot.md#sample_hovered) and [`sample_clicked`](tau_plot.md#sample_clicked) carrying arrays of `SampleHit`.
* [`TauHoverConfig`](hover_config.md) Configures the hover inspection system that produces `SampleHit` instances. Callbacks [`format_tooltip_text`](hover_config.md#format_tooltip_text) and [`create_tooltip_control`](hover_config.md#create_tooltip_control) receive these arrays.
* [`Dataset`](dataset.md) Source of the series data that [`series_id`](#series_id), [`series_name`](#series_name), and [`sample_index`](#sample_index) refer back to.