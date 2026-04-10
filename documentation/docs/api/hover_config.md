# TauHoverConfig

!!! info ""
    **Inherits:** `Resource`  

Configures the hover inspection system: hover mode, highlight, tooltip, and crosshair.

## Description

`TauHoverConfig` is the configuration object for the hover inspection system in [`TauPlot`](tau_plot.md). It is assigned to [`TauPlot.hover_config`](tau_plot.md#hover_config). The system activates when [`TauPlot.hover_enabled`](tau_plot.md#hover_enabled) is `true`. When `hover_config` is `null`, built-in defaults apply for all settings.

The **hover mode** controls which samples are collected when the cursor moves over a pane:

- [`NEAREST`](#hovermode) collects the single closest sample across all overlays in the pane.
- [`X_ALIGNED`](#hovermode) collects all samples at the nearest X position across every overlay in the pane. For [`PER_SERIES_X`](dataset.md#mode) datasets, only series that have a data point at the globally nearest X are included (see the [enum table](#hovermode) for details).
- [`AUTO`](#hovermode) resolves the mode per pane from its overlay composition.

The **highlight** sub-system adjusts sample colors during rendering based on hover state. [`highlight_enabled`](#highlight_enabled) toggles it. When active, [`hover_highlight_callback`](#hover_highlight_callback) is called once per sample at draw time to perform the color adjustment. The callback must be valid to have any effect. When it is not set, the built-in behavior brightens the hovered sample and dims all other samples. For [`GROUPED`](bar_config.md#barmode) bars in [`X_ALIGNED`](#hovermode) mode, the entire group at the hovered X position is highlighted together rather than a single bar. The callback is only invoked while at least one sample is hovered.

The **tooltip** sub-system renders a popup near the hovered position. [`tooltip_enabled`](#tooltip_enabled) governs whether the built-in popup appears:

- When `false`, no popup is rendered. The hover signals ([`sample_hovered`](tau_plot.md#sample_hovered), [`sample_hover_exited`](tau_plot.md#sample_hover_exited), [`sample_clicked`](tau_plot.md#sample_clicked), [`sample_click_dismissed`](tau_plot.md#sample_click_dismissed)) still fire, making this the right setting when driving a custom UI from those signals.
- When `true`, the built-in popup is rendered. Its content is determined in priority order:
  - [`create_tooltip_control`](#create_tooltip_control), when set, supplies a `Control` node placed inside the popup as its content, replacing the default text and giving full control over layout and presentation.
  - [`format_tooltip_text`](#format_tooltip_text), when set and [`create_tooltip_control`](#create_tooltip_control) is not, supplies a BBCode string rendered inside the popup.
  - When neither callback is set, the built-in formatter renders the series name and sample values.

The popup exists in two states: a **transient** state that follows or anchors near the cursor, and a **pinned** state that stays visible after a click and is dismissed explicitly. Visual properties for both states are controlled through [`tooltip_style`](#tooltip_style).

[`tooltip_position_mode`](#tooltip_position_mode) controls whether the popup anchors to the data point or follows the cursor. [`tooltip_precision_digits`](#tooltip_precision_digits) sets the number of significant digits used when the built-in formatter renders numeric values.

The **crosshair** sub-system draws guide lines across the pane at the hovered position. [`crosshair_mode`](#crosshair_mode) selects which lines are drawn. Visual properties are set on [`crosshair_style`](#crosshair_style).

[`tooltip_style`](#tooltip_style) and [`crosshair_style`](#crosshair_style) are created automatically when `TauHoverConfig` is instantiated, so they are never `null`.

### Example

```gdscript
var hover := TauHoverConfig.new()
hover.hover_mode = TauHoverConfig.HoverMode.X_ALIGNED
hover.crosshair_mode = TauHoverConfig.CrosshairMode.X_ONLY
hover.tooltip_precision_digits = 4

# Replace the built-in tooltip text with a custom BBCode string.
hover.format_tooltip_text = func(hits: Array[TauPlot.SampleHit]) -> String:
    return "[b]%s[/b]: %.4f" % [hits[0].series_name, hits[0].y_value]

%MyPlot.hover_config = hover
%MyPlot.hover_enabled = true
```

### Notes

1. **Non-serializable callbacks.** [`hover_highlight_callback`](#hover_highlight_callback), [`format_tooltip_text`](#format_tooltip_text), and [`create_tooltip_control`](#create_tooltip_control) are not exported and cannot be saved in a `.tres` resource file. Assign them at runtime only.

2. **Duplicate hits.** The array passed to [`format_tooltip_text`](#format_tooltip_text) and [`create_tooltip_control`](#create_tooltip_control) is not deduplicated. If a series is bound to multiple overlays, multiple [`SampleHit`](sample_hit.md) entries with the same `series_id` and `sample_index` may appear. The callback is responsible for handling duplicates.

## Enums

### `HoverMode`

Controls which samples are collected when the cursor moves over a pane.

| Value | Meaning |
|---|---|
| `AUTO` | The mode is resolved per pane based on the overlay types it contains. |
| `NEAREST` | The single closest sample across all overlays in the pane is collected. |
| `X_ALIGNED` | All samples at the nearest X position across every overlay in the pane are collected. For [`SHARED_X`](dataset.md#mode) datasets every series has a value at that position, so all series appear in the tooltip. For [`PER_SERIES_X`](dataset.md#mode) datasets the nearest X is found across all series, and only series that have a data point at that exact X are included. Two X values are considered equal when their relative difference is smaller than `1e-9`. In practice this means most hover events on a `PER_SERIES_X` dataset produce a single-series tooltip, but when two series happen to share the same X value both appear. |

---

### `CrosshairMode`

Controls which crosshair guide lines are drawn at the hovered position.

| Value | Meaning |
|---|---|
| `NONE` | No crosshair lines are drawn. |
| `X_ONLY` | A vertical line is drawn at the hovered X position, spanning the full pane extent along the Y direction. |
| `Y_ONLY` | A horizontal line is drawn at the hovered Y position, spanning the full pane extent along the X direction. |
| `BOTH` | Both the vertical and horizontal lines are drawn. |

---

### `TooltipPositionMode`

Controls where the tooltip popup is anchored.

| Value | Meaning |
|---|---|
| `SNAP_TO_POINT` | The tooltip anchors to the hovered data point with an offset defined by [`TauTooltipStyle.offset_px`](tooltip_style.md#offset_px). For [`GROUPED`](bar_config.md#barmode) bars in [`X_ALIGNED`](#hovermode) mode, the anchor is the center of the group (horizontally at the category center, vertically at the top of the tallest bar). |
| `FOLLOW_MOUSE` | The tooltip follows the cursor with the same offset. |

## Constructor

### `new()`

```gdscript
TauHoverConfig.new() -> TauHoverConfig
```

Creates a new `TauHoverConfig` with all properties set to their built-in defaults. [`tooltip_style`](#tooltip_style) and [`crosshair_style`](#crosshair_style) are initialized automatically and are never `null`.

## Properties

### hover_mode

`hover_mode`: [`HoverMode`](#hovermode)

The strategy used to collect samples when the cursor moves over a pane. Default is [`AUTO`](#hovermode).

[`AUTO`](#hovermode) resolves the mode per pane from its overlay composition:

- A pane containing only bar overlays resolves to [`X_ALIGNED`](#hovermode).
- A pane containing only scatter overlays resolves to [`NEAREST`](#hovermode).
- A pane mixing both overlay types resolves to [`NEAREST`](#hovermode).

[`NEAREST`](#hovermode) collects the single closest sample. [`X_ALIGNED`](#hovermode) collects all samples at the nearest X position. For [`PER_SERIES_X`](dataset.md#mode) datasets, `X_ALIGNED` finds the globally nearest X across all series and only includes series whose closest X matches that value (relative tolerance of `1e-9`).

---

### highlight_enabled

`highlight_enabled`: `bool`

Controls whether hovered samples receive a visual color adjustment during rendering. Default is `true`.

When `true`, [`hover_highlight_callback`](#hover_highlight_callback) is called once per sample at draw time to perform the adjustment. The callback must be valid to have any effect. When the callback is not set, the built-in behavior applies instead: the hovered sample is brightened and all other samples are dimmed. For [`GROUPED`](bar_config.md#barmode) bars in [`X_ALIGNED`](#hovermode) mode, all bars at the hovered X position are brightened together. When `false`, all samples use their normal resolved colors regardless of hover state and [`hover_highlight_callback`](#hover_highlight_callback) is never called.

---

### hover_highlight_callback

`hover_highlight_callback`: `Callable`

An optional callback that returns the draw color for each sample based on hover state. Default is an invalid `Callable`.

When invalid, the built-in behavior applies: the hovered sample is brightened and all other samples are dimmed. When valid, the callback replaces that behavior entirely. It is only invoked when [`highlight_enabled`](#highlight_enabled) is `true` and at least one sample is currently hovered. See [note 1](#notes). The callback signature is:

```gdscript
func(color: Color, hovered: bool) -> Color
```

`color` is the resolved fill color for the sample. `hovered` is `true` when this specific sample is the one under the cursor. For [`GROUPED`](bar_config.md#barmode) bars in [`X_ALIGNED`](#hovermode) mode, `hovered` is `true` for every bar in the hovered group, not just the one directly under the cursor. The return value is the color the renderer draws.

---

### tooltip_enabled

`tooltip_enabled`: `bool`

Controls whether the built-in tooltip popup is rendered. Default is `true`.

When `false`, the popup does not appear. The hover signals ([`sample_hovered`](tau_plot.md#sample_hovered), [`sample_hover_exited`](tau_plot.md#sample_hover_exited), [`sample_clicked`](tau_plot.md#sample_clicked), [`sample_click_dismissed`](tau_plot.md#sample_click_dismissed)), highlight, and crosshair are not affected.

---

### tooltip_position_mode

`tooltip_position_mode`: [`TooltipPositionMode`](#tooltippositionmode)

Controls where the tooltip popup is anchored relative to the hovered position. Default is [`SNAP_TO_POINT`](#tooltippositionmode).

---

### tooltip_precision_digits

`tooltip_precision_digits`: `int`

The number of significant digits used when the built-in formatter renders numeric sample values in the tooltip. Default is `3`.

The displayed precision adapts to the visible domain span. A narrow span produces more decimal places. A wide span produces fewer. Valid range is `1` to `15`. This property has no effect when [`format_tooltip_text`](#format_tooltip_text) or [`create_tooltip_control`](#create_tooltip_control) is set.

---

### tooltip_style

`tooltip_style`: [`TauTooltipStyle`](tooltip_style.md)

The visual style applied to the tooltip popup. Default is a freshly constructed [`TauTooltipStyle`](tooltip_style.md) with all built-in defaults.

Never `null`. Modify properties directly on the instance. Any property left at its built-in default remains overridable by the active Godot theme. Multiple `TauHoverConfig` instances can share the same [`TauTooltipStyle`](tooltip_style.md) resource.

---

### crosshair_mode

`crosshair_mode`: [`CrosshairMode`](#crosshairmode)

The crosshair lines drawn at the hovered position. Default is [`NONE`](#crosshairmode).

---

### crosshair_style

`crosshair_style`: [`TauCrosshairStyle`](crosshair_style.md)

The visual style applied to the crosshair lines. Default is a freshly constructed [`TauCrosshairStyle`](crosshair_style.md) with all built-in defaults.

Never `null`. Modify properties directly on the instance. Any property left at its built-in default remains overridable by the active Godot theme. Multiple `TauHoverConfig` instances can share the same [`TauCrosshairStyle`](crosshair_style.md) resource.

---

### format_tooltip_text

`format_tooltip_text`: `Callable`

An optional callback that returns the tooltip content as a BBCode string. Default is an invalid `Callable`.

When valid, replaces the built-in text formatter. When invalid, the built-in formatter renders the series name and sample values using [`tooltip_precision_digits`](#tooltip_precision_digits). Ignored when [`create_tooltip_control`](#create_tooltip_control) is set. See [note 1](#notes) and [note 2](#notes). The callback signature is:

```gdscript
func(hits: Array[SampleHit]) -> String
```

`hits` is the array of [`SampleHit`](sample_hit.md) objects describing the currently hovered samples.

---

### create_tooltip_control

`create_tooltip_control`: `Callable`

An optional callback that returns a `Control` node placed inside the tooltip panel as its content. Default is an invalid `Callable`.

When valid, takes priority over [`format_tooltip_text`](#format_tooltip_text). The returned Control is added as a child of the tooltip panel and padded by [`TauTooltipStyle.padding_px`](tooltip_style.md#padding_px) on all sides. The panel's background and positioning are still governed by [`tooltip_style`](#tooltip_style). The Control is freed when the tooltip hides. See [note 1](#notes) and [note 2](#notes). The callback signature is:

```gdscript
func(hits: Array[SampleHit]) -> Control
```

`hits` is the array of [`SampleHit`](sample_hit.md) objects describing the currently hovered samples.

## Related Classes

* [`TauPlot`](tau_plot.md) The plot node. Accepts `TauHoverConfig` via [`hover_config`](tau_plot.md#hover_config) and activates the system when [`hover_enabled`](tau_plot.md#hover_enabled) is `true`.
* [`TauTooltipStyle`](tooltip_style.md) Controls the visual appearance of the tooltip popup, assigned to [`tooltip_style`](#tooltip_style).
* [`TauCrosshairStyle`](crosshair_style.md) Controls the visual appearance of the crosshair lines, assigned to [`crosshair_style`](#crosshair_style).
* [`SampleHit`](sample_hit.md) Describes one hovered sample. Passed to [`format_tooltip_text`](#format_tooltip_text) and [`create_tooltip_control`](#create_tooltip_control).
* [`TauXYStyle`](xy_style.md) Provides the fallback font and font size used by the built-in tooltip formatter.