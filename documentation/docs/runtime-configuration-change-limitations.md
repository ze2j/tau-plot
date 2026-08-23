# Runtime Configuration Change Limitations

The plot keeps a reference to the configuration objects you pass to [`plot_xy()`](api/tau_plot.md#plot_xy). To change a property on one of them while the plot is displayed, assign the property, then call [`TauPlot.queue_refresh()`](api/tau_plot.md#queue_refresh) or [`TauPlot.refresh_now()`](api/tau_plot.md#refresh_now).

Some properties do not work that way yet. The tables below list every configuration property and tell you which ones do.

- **OK**: you change the property, you call `queue_refresh()`, the plot shows the change.
- **KO**: the change is not applied. The comment tells you what to do instead.

Setting a property before [`plot_xy()`](api/tau_plot.md#plot_xy) always works. This page is only about changing it after.

## [TauXYConfig](api/xy_config.md)

| Property | Type | Status | Comment |
|---|---|---|---|
| x_axis_id | `AxisId` | KO | Not applied. Workaround: call `plot_xy()` again. |
| x_axis | `TauAxisConfig` | KO | Assigning a new instance is not detected. Workaround: call `plot_xy()` again. |
| secondary_x_axis | `TauAxisConfig` | KO | Not applied, and neither are the properties of the assigned instance. Workaround: call `plot_xy()` again. |
| secondary_x_axis_transform | `Callable` | KO | Same as `secondary_x_axis`. |
| panes | `Array[TauPaneConfig]` | KO | Adding, removing or replacing an entry is not detected. Workaround: call `plot_xy()` again. |
| style | `TauXYStyle` | OK | |

## [TauPaneConfig](api/pane_config.md)

| Property | Type | Status | Comment |
|---|---|---|---|
| y_bottom_axis | `TauAxisConfig` | KO | Assigning a new instance is not detected. Workaround: call `plot_xy()` again. |
| y_top_axis | `TauAxisConfig` | KO | Same as `y_bottom_axis`. |
| y_left_axis | `TauAxisConfig` | KO | Same as `y_bottom_axis`. |
| y_right_axis | `TauAxisConfig` | KO | Same as `y_bottom_axis`. |
| overlays | `Array[TauPaneOverlayConfig]` | KO | Adding, removing or replacing an entry is not detected. Workaround: call `plot_xy()` again. |
| style | `TauPaneStyle` | OK | |
| grid_line | `TauGridLineConfig` | OK | |
| stretch_ratio | `float` | OK | |
| align_y_axes_at_zero | `bool` | KO | Not applied. Workaround: call `plot_xy()` again. |

## [TauAxisConfig](api/axis_config.md)

This table applies to the primary X axis and to every Y axis.

| Property | Type | Status | Comment |
|---|---|---|---|
| type | `Type` | KO | Not applied. Workaround: call `plot_xy()` again. |
| scale | `Scale` | KO | Same as `type`. |
| inverted | `bool` | OK | |
| include_zero_in_domain | `bool` | KO | Same as `type`. |
| title | `String` | KO | Same as `type`. |
| title_orientation | `TitleOrientation` | KO | Same as `type`. |
| title_alignment | `TitleAlignment` | KO | Same as `type`. |
| title_text_alignment | `TextAlignment` | KO | Same as `type`. |
| format_tick_label | `Callable` | KO | Same as `type`. |
| tick_count_preferred | `int` | OK | |
| overlap_strategy | `OverlapStrategy` | OK | |
| min_label_spacing_px | `int` | OK | |
| range_override_enabled | `bool` | KO | Same as `type`. |
| min_override | `float` | KO | Same as `type`. |
| max_override | `float` | KO | Same as `type`. |
| domain_padding_mode | `DomainPaddingMode` | KO | Same as `type`. |
| domain_padding_min | `float` | KO | Same as `type`. |
| domain_padding_max | `float` | KO | Same as `type`. |

## [TauPaneOverlayConfig](api/pane_overlay_config.md)

The base class of the overlay configurations. These properties are available on `TauBarConfig`, `TauScatterConfig` and `TauLineConfig`.

| Property | Type | Status | Comment |
|---|---|---|---|
| z_order | `ZOrder` | OK | |
| visual_callbacks | `VisualCallbacks` | KO | Assigning a new instance is not detected. Workaround: call `plot_xy()` again. |
| hoverable | `bool` | OK | |

## [TauBarConfig](api/bar_config.md)

| Property | Type | Status | Comment |
|---|---|---|---|
| mode | `BarMode` | OK | |
| stacked_normalization | `StackedNormalization` | OK | |
| stacked_negative_policy | `StackedNegativePolicy` | OK | |
| bar_width_policy | `BarWidthPolicy` | OK | |
| category_width_fraction | `float` | OK | |
| intra_group_gap_fraction | `float` | OK | |
| bar_width_x_units | `float` | OK | |
| bar_gap_x_units | `float` | OK | |
| bar_width_log_factor | `float` | OK | |
| bar_gap_log_factor | `float` | OK | |
| neighbor_spacing_fraction | `float` | OK | |
| neighbor_gap_fraction | `float` | OK | |
| style | `TauBarStyle` | OK | |
| bar_visual_callbacks | `BarVisualCallbacks` | KO | Same as `TauPaneOverlayConfig.visual_callbacks`. |

## [TauScatterConfig](api/scatter_config.md)

| Property | Type | Status | Comment |
|---|---|---|---|
| marker_size_policy | `MarkerSizePolicy` | OK | |
| marker_size_data_units | `float` | OK | |
| hover_max_distance_px | `int` | OK | |
| style | `TauScatterStyle` | OK | |
| scatter_visual_callbacks | `ScatterVisualCallbacks` | KO | Same as `TauPaneOverlayConfig.visual_callbacks`. |

## [TauLineConfig](api/line_config.md)

| Property | Type | Status | Comment |
|---|---|---|---|
| mode | `LineMode` | OK | |
| interpolation_modes | `Array[InterpolationMode]` | OK | |
| gap_policy | `GapPolicy` | OK | |
| stacked_normalization | `StackedNormalization` | OK | |
| stacked_negative_policy | `StackedNegativePolicy` | OK | |
| hover_max_distance_px | `int` | OK | |
| style | `TauLineStyle` | OK | |
| line_visual_callbacks | `LineVisualCallbacks` | KO | Same as `TauPaneOverlayConfig.visual_callbacks`. |

## [TauGridLineConfig](api/grid_line_config.md)

| Property | Type | Status | Comment |
|---|---|---|---|
| x_source_axis_id | `AxisId` | OK | |
| y_source_axis_id | `AxisId` | OK | |
| x_major_enabled | `bool` | OK | |
| x_minor_enabled | `bool` | OK | |
| y_major_enabled | `bool` | OK | |
| y_minor_enabled | `bool` | OK | |

## [TauHoverConfig](api/hover_config.md)

| Property | Type | Status | Comment |
|---|---|---|---|
| hover_mode | `HoverMode` | OK | |
| highlight_enabled | `bool` | OK | |
| hover_highlight_callback | `Callable` | OK | |
| tooltip_enabled | `bool` | OK | |
| tooltip_position_mode | `TooltipPositionMode` | OK | |
| tooltip_precision_digits | `int` | KO | Not applied. Workaround: call `plot_xy()` again. |
| tooltip_style | `TauTooltipStyle` | KO | Assigning a new instance is not detected. Changing a property on the current instance works. Workaround: build a new `TauHoverConfig` and assign it to [`TauPlot.hover_config`](api/tau_plot.md#hover_config). |
| crosshair_mode | `CrosshairMode` | OK | |
| crosshair_style | `TauCrosshairStyle` | KO | Same as `tooltip_style`. |
| format_tooltip_text | `Callable` | OK | |
| create_tooltip_control | `Callable` | OK | |

## [TauLegendConfig](api/legend_config.md)

| Property | Type | Status | Comment |
|---|---|---|---|
| position | `Position` | KO | Not applied. Workaround: build a new `TauLegendConfig` and assign it to [`TauPlot.legend_config`](api/tau_plot.md#legend_config). |
| flow_direction | `FlowDirection` | KO | Same as `position`. |
| style | `TauLegendStyle` | KO | Assigning a new instance is not detected. Changing a property on the current instance works. Workaround: build a new `TauLegendConfig` and assign it to [`TauPlot.legend_config`](api/tau_plot.md#legend_config). |