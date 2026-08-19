# TauHoverConfig

!!! info ""
    **Inherits:** `Resource`  

Configures the hover inspection system: hover mode, highlight, tooltip, and crosshair.

## Description

`TauHoverConfig` is the configuration object for the hover inspection system in [`TauPlot`](tau_plot.md). It is assigned to [`TauPlot.hover_config`](tau_plot.md#hover_config). The system activates when [`TauPlot.hover_enabled`](tau_plot.md#hover_enabled) is `true`. When `hover_config` is `null`, built-in defaults apply for all settings.

The **hover mode** controls which samples are collected when the cursor moves over a pane:

- [`NEAREST`](#hovermode) collects the single closest sample across all overlays in the pane.
- [`X_ALIGNED`](#hovermode) collects all samples at the nearest X position across every overlay in the pane. For [`PER_SERIES_X`](dataset.md#mode) datasets, only series that have a data point at the globally nearest X are included (see the [enum table](#hovermode) for details).
- [`AUTO`](#hovermode) resolves the mode per pane by a vote. Each [`hoverable`](pane_overlay_config.md#hoverable) overlay in the pane states a preferred mode: [`X_ALIGNED`](#hovermode) for a [`BAR`](tau_plot.md#paneoverlaytype) or [`LINE`](tau_plot.md#paneoverlaytype) overlay, [`NEAREST`](#hovermode) for a [`SCATTER`](tau_plot.md#paneoverlaytype) overlay. Unanimity wins. A disagreement resolves to [`NEAREST`](#hovermode), and so does a pane holding no hoverable overlay.

The **highlight** sub-system emphasizes the hovered samples while the cursor stays over a pane. [`highlight_enabled`](#highlight_enabled) toggles it. It changes the drawing in two ways.

First, the emphasized sample of an overlay takes the hovered-state properties of that overlay's style: [`TauBarStyle.hovered_style_box`](bar_style.md#hovered_style_box), [`TauScatterStyle.hovered_marker_sizes_px`](scatter_style.md#hovered_marker_sizes_px) with [`hovered_outline_width_px`](scatter_style.md#hovered_outline_width_px) and [`hovered_outline_color`](scatter_style.md#hovered_outline_color), and [`TauLineStyle.hovered_line_widths_px`](line_style.md#hovered_line_widths_px).

Second, the plot changes the color of every sample of the pane. By default it brightens the emphasized sample and dims the other ones. [`hover_highlight_callback`](#hover_highlight_callback) replaces that default. When it is set, the plot calls it once per sample and draws the color it returns.

The highlight only affects the pane under the cursor. The other panes keep their normal colors. Inside that pane, the highlight runs only when one of its overlays has an emphasized sample. When none has, every sample keeps its normal color, and the tooltip still lists its hits. An overlay whose [`hoverable`](pane_overlay_config.md#hoverable) is `false` stays out of the highlight and keeps its normal colors.

At most one sample per overlay and per pane is emphasized, picked from the hits the hover mode collected:

- A [`BAR`](tau_plot.md#paneoverlaytype) or [`SCATTER`](tau_plot.md#paneoverlaytype) overlay considers only hits whose [`SampleHit.contains_pointer`](sample_hit.md#contains_pointer) is `true`, and emphasizes the closest of those by [`SampleHit.distance_px`](sample_hit.md#distance_px). When the cursor is inside no element, the tooltip still lists every hit and nothing is emphasized.
- A [`LINE`](tau_plot.md#paneoverlaytype) overlay emphasizes the closest hit by [`SampleHit.distance_px`](sample_hit.md#distance_px), whatever [`contains_pointer`](sample_hit.md#contains_pointer) holds, so the curve running nearest the cursor takes the emphasis.
- [`GROUPED`](bar_config.md#barmode) bars in [`X_ALIGNED`](#hovermode) mode are emphasized as a group. Every bar at the hovered X position takes the hovered state, with no containment requirement.

The **tooltip** sub-system renders a popup near the hovered position. [`tooltip_enabled`](#tooltip_enabled) governs whether the built-in popup appears:

- When `false`, no popup is rendered. The hover signals ([`sample_hovered`](tau_plot.md#sample_hovered), [`sample_hover_exited`](tau_plot.md#sample_hover_exited), [`sample_clicked`](tau_plot.md#sample_clicked), [`sample_click_dismissed`](tau_plot.md#sample_click_dismissed)) still fire, making this the right setting when driving a custom UI from those signals.
- When `true`, the built-in popup is rendered. Its content is determined in priority order:
  - [`create_tooltip_control`](#create_tooltip_control), when set, supplies a `Control` node placed inside the popup as its content, replacing the default text and giving full control over layout and presentation.
  - [`format_tooltip_text`](#format_tooltip_text), when set and [`create_tooltip_control`](#create_tooltip_control) is not, supplies a BBCode string rendered inside the popup.
  - When neither callback is set, the built-in formatter renders the hits after deduplicating them by [`series_id`](sample_hit.md#series_id) and [`sample_index`](sample_hit.md#sample_index). A single hit renders as the series name followed by the X value in parentheses, then a second line holding `y: ` and the Y value. Several hits render the X value on the first line, then one line per hit holding the series name and its Y value. The Y value is [`SampleHit.y_raw_value`](sample_hit.md#y_raw_value), so a stacked overlay reports what the dataset holds rather than the cumulative top.

The popup exists in two states: a **transient** state that follows or anchors near the cursor, and a **pinned** state that a click leaves in place. A click on empty space or the Escape key dismisses a pinned popup. Visual properties for both states are controlled through [`tooltip_style`](#tooltip_style).

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
    return "[b]%s[/b]: %.4f" % [hits[0].series_name, hits[0].y_raw_value]

%MyPlot.hover_config = hover
%MyPlot.hover_enabled = true
```

### Notes

1. **Duplicate hits.** The array passed to [`format_tooltip_text`](#format_tooltip_text) and [`create_tooltip_control`](#create_tooltip_control) is not deduplicated. A series bound to several overlays produces one [`SampleHit`](sample_hit.md) per overlay, with the same [`series_id`](sample_hit.md#series_id) and [`sample_index`](sample_hit.md#sample_index). A custom callback handles that itself. The built-in formatter deduplicates on those two fields and keeps the first hit of each pair.

## Enums

### `HoverMode`

Controls which samples are collected when the cursor moves over a pane.

| Value | Meaning |
|---|---|
| `AUTO` | The mode is resolved per pane by a vote between the hoverable overlays it contains. Bar and line overlays prefer `X_ALIGNED`, scatter overlays prefer `NEAREST`. A disagreement, or a pane with no hoverable overlay, resolves to `NEAREST`. |
| `NEAREST` | The single closest sample across all overlays in the pane is collected. |
| `X_ALIGNED` | All samples at the nearest X position across every overlay in the pane are collected. For [`SHARED_X`](dataset.md#mode) datasets every series has a value at that position, so all series appear in the tooltip. For [`PER_SERIES_X`](dataset.md#mode) datasets the nearest X is found across all series, and only series that have a data point at that exact X are included. Two X values count as equal when their relative difference is at or below `1e-9`. In practice this means most hover events on a `PER_SERIES_X` dataset produce a single-series tooltip, but when two series happen to share the same X value both appear. |

---

### `CrosshairMode`

Controls which crosshair guide lines are drawn at the hovered position.

| Value | Meaning |
|---|---|
| `NONE` | No crosshair lines are drawn. |
| `X_ONLY` | One line is drawn at the hovered X position, running across the pane perpendicular to the X axis. |
| `Y_ONLY` | One line is drawn at the hovered Y position, running across the pane perpendicular to the Y axis. |
| `BOTH` | Both lines are drawn. |

---

### `TooltipPositionMode`

Controls where the tooltip popup is anchored.

| Value | Meaning |
|---|---|
| `SNAP_TO_POINT` | The tooltip anchors to the hovered data point with an offset defined by [`TauTooltipStyle.offset_px`](tooltip_style.md#offset_px). For [`GROUPED`](bar_config.md#barmode) bars in [`X_ALIGNED`](#hovermode) mode, the anchor sits at the category center along the X axis and at the tip of the tallest bar along the Y axis. |
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

The mode applies to every pane. [`AUTO`](#hovermode) is the one value resolved per pane, from the overlays that pane holds.

---

### highlight_enabled

`highlight_enabled`: `bool`

Controls whether hovered samples are emphasized during rendering. Default is `true`.

When `false`, every sample draws with its normal resolved color and style whatever the hover state, and [`hover_highlight_callback`](#hover_highlight_callback) is never called.

---

### hover_highlight_callback

`hover_highlight_callback`: `Callable`

An optional callback that returns the draw color of each sample from its hover state. Default is an invalid `Callable`.

When invalid, the built-in behavior applies: the emphasized sample is brightened, and the alpha channel of every other sample is multiplied by `0.7`, so a series already translucent stays behind an opaque one. When valid, the callback replaces that behavior for the color, and the hovered-state style properties still apply. It is invoked once per sample of every [`hoverable`](pane_overlay_config.md#hoverable) overlay of the pane under the cursor, while [`highlight_enabled`](#highlight_enabled) is `true` and a sample of that pane is emphasized. The callback signature is:

```gdscript
func(color: Color, hovered: bool) -> Color
```

* `color: Color` The resolved fill color of the sample.
* `hovered: bool` `true` when this sample is the emphasized one of its overlay. For [`GROUPED`](bar_config.md#barmode) bars in [`X_ALIGNED`](#hovermode) mode, `true` for every bar of the hovered group.

The return value is the color the renderer draws.

`hover_highlight_callback` is not serializable. The property is not exported and cannot be saved in a `.tres` resource file. Assign it at runtime only.

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

The displayed precision adapts to the visible domain span. A narrow span produces more decimal places. A wide span produces fewer. Valid range is `1` to `15`, and a value outside it is clamped into that range on assignment. This property has no effect when [`format_tooltip_text`](#format_tooltip_text) or [`create_tooltip_control`](#create_tooltip_control) is set.

---

### tooltip_style

`tooltip_style`: [`TauTooltipStyle`](tooltip_style.md)

The visual style applied to the tooltip popup. Default is a freshly constructed [`TauTooltipStyle`](tooltip_style.md) with all built-in defaults.

Never `null`. Modify properties directly on the instance. Any property left unassigned on this instance can still be set by the active Godot theme. Multiple `TauHoverConfig` instances can share the same [`TauTooltipStyle`](tooltip_style.md) resource.

---

### crosshair_mode

`crosshair_mode`: [`CrosshairMode`](#crosshairmode)

The crosshair lines drawn at the hovered position. Default is [`NONE`](#crosshairmode).

---

### crosshair_style

`crosshair_style`: [`TauCrosshairStyle`](crosshair_style.md)

The visual style applied to the crosshair lines. Default is a freshly constructed [`TauCrosshairStyle`](crosshair_style.md) with all built-in defaults.

Never `null`. Modify properties directly on the instance. Any property left unassigned on this instance can still be set by the active Godot theme. Multiple `TauHoverConfig` instances can share the same [`TauCrosshairStyle`](crosshair_style.md) resource.

---

### format_tooltip_text

`format_tooltip_text`: `Callable`

An optional callback that returns the tooltip content as a BBCode string. Default is an invalid `Callable`.

When valid, replaces the built-in text formatter. When invalid, the built-in formatter renders the series name and sample values using [`tooltip_precision_digits`](#tooltip_precision_digits). Ignored when [`create_tooltip_control`](#create_tooltip_control) is set. See [note 1](#notes). The callback signature is:

```gdscript
func(hits: Array[SampleHit]) -> String
```

* `hits: Array[SampleHit]` The [`SampleHit`](sample_hit.md) objects describing the currently hovered samples.

`format_tooltip_text` is not serializable. The property is not exported and cannot be saved in a `.tres` resource file. Assign it at runtime only.

---

### create_tooltip_control

`create_tooltip_control`: `Callable`

An optional callback that returns a `Control` node placed inside the tooltip panel as its content. Default is an invalid `Callable`.

When valid, takes priority over [`format_tooltip_text`](#format_tooltip_text). The returned `Control` is added as a child of the tooltip panel and padded by [`TauTooltipStyle.padding_px`](tooltip_style.md#padding_px) on all sides. The panel background and positioning are still governed by [`tooltip_style`](#tooltip_style). The `Control` is freed when the tooltip hides. See [note 1](#notes). The callback signature is:

```gdscript
func(hits: Array[SampleHit]) -> Control
```

* `hits: Array[SampleHit]` The [`SampleHit`](sample_hit.md) objects describing the currently hovered samples.

`create_tooltip_control` is not serializable. The property is not exported and cannot be saved in a `.tres` resource file. Assign it at runtime only.

## Related Classes

* [`TauPlot`](tau_plot.md) The plot node. Accepts `TauHoverConfig` via [`hover_config`](tau_plot.md#hover_config) and activates the system when [`hover_enabled`](tau_plot.md#hover_enabled) is `true`.
* [`SampleHit`](sample_hit.md) Describes one hovered sample. Passed to [`format_tooltip_text`](#format_tooltip_text) and [`create_tooltip_control`](#create_tooltip_control).
* [`Dataset`](dataset.md) The data model. Its [mode](dataset.md#mode) decides how many series [`X_ALIGNED`](#hovermode) collects at one X position.
* [`TauPaneOverlayConfig`](pane_overlay_config.md) Base class of the overlay configurations. Its [`hoverable`](pane_overlay_config.md#hoverable) flag takes an overlay out of hit testing, out of the highlight, and out of the [`AUTO`](#hovermode) vote.
* [`TauBarConfig`](bar_config.md) Bar overlay configuration. Its [`mode`](bar_config.md#mode) decides whether bars are emphasized one at a time or as a group.
* [`TauScatterConfig`](scatter_config.md) Scatter overlay configuration. Holds the [`hover_max_distance_px`](scatter_config.md#hover_max_distance_px) gate applied to markers.
* [`TauLineConfig`](line_config.md) Line overlay configuration. Holds the [`hover_max_distance_px`](line_config.md#hover_max_distance_px) gate applied to curve samples.
* [`TauBarStyle`](bar_style.md) Holds [`hovered_style_box`](bar_style.md#hovered_style_box), applied to the emphasized bar.
* [`TauScatterStyle`](scatter_style.md) Holds the hovered-state marker size, outline width, and outline color.
* [`TauLineStyle`](line_style.md) Holds [`hovered_line_widths_px`](line_style.md#hovered_line_widths_px), applied around the emphasized sample.
* [`TauTooltipStyle`](tooltip_style.md) Controls the visual appearance of the tooltip popup, assigned to [`tooltip_style`](#tooltip_style).
* [`TauCrosshairStyle`](crosshair_style.md) Controls the visual appearance of the crosshair lines, assigned to [`crosshair_style`](#crosshair_style).