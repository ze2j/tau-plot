# API Reference

This section documents the public classes of TauPlot.

## Entry point

- [`TauPlot`](tau_plot.md): The plot node.

## Data classes

- [`Dataset`](dataset.md): Data container holding series and samples.
- [`DatasetChange`](dataset_change.md): Payload of the `Dataset.changed` signal, describing one mutation.
- [`ColorBuffer`](color_buffer.md): Per-sample `Color` buffer.
- [`Float32Buffer`](float32_buffer.md): Per-sample `float32` buffer.
- [`Float64Buffer`](float64_buffer.md): Per-sample `float64` buffer.
- [`Int32Buffer`](int32_buffer.md): Per-sample `int32` buffer.
- [`StringBuffer`](string_buffer.md): Per-sample `String` buffer.

## Series binding

- [`TauXYSeriesBinding`](xy_series_binding.md): Maps a dataset series to a pane, overlay, and y axis.

## Plot configuration

- [`TauXYConfig`](xy_config.md): Top-level XY plot configuration.
- [`TauPaneConfig`](pane_config.md): Pane configuration.
- [`TauAxisConfig`](axis_config.md): Axis configuration.
- [`TauPaneOverlayConfig`](pane_overlay_config.md): Abstract base class of overlay configurations.
- [`TauBarConfig`](bar_config.md): Bar-specific rendering configuration.
- [`TauScatterConfig`](scatter_config.md): Scatter-specific rendering configuration.
- [`TauLineConfig`](line_config.md): Line-specific rendering configuration.

## Additional configuration

- [`TauLegendConfig`](legend_config.md): Legend configuration including position, flow direction, and style.
- [`TauGridLineConfig`](grid_line_config.md): Grid line configuration.
- [`TauHoverConfig`](hover_config.md): Hover configuration including highlight, tooltip and crosshair.
- [`SampleHit`](sample_hit.md): Read-only data object produced by the hover inspection system.

## Style resources

- [`TauStyle`](style.md): Abstract base class of styles.
- [`TauXYStyle`](xy_style.md): Visual appearance of the plot.
- [`TauPaneStyle`](pane_style.md): Visual appearance of a pane.
- [`TauBarStyle`](bar_style.md): Visual appearance of `BAR` overlays.
- [`TauScatterStyle`](scatter_style.md): Visual appearance of `SCATTER` overlays.
- [`TauLineStyle`](line_style.md): Visual appearance of `LINE` overlays.
- [`TauLineFill`](line_fill.md): Area painted around the curve of one series in a `LINE` overlay.
- [`TauLegendStyle`](legend_style.md): Visual appearance of the legend.
- [`TauTooltipStyle`](tooltip_style.md): Tooltip visual style.
- [`TauCrosshairStyle`](crosshair_style.md): Crosshair visual style.

## Per-sample visual attributes (data-driven)

- [`VisualAttributes`](visual_attributes.md): Abstract base class of per-sample attributes.
- [`BarVisualAttributes`](bar_visual_attributes.md): Per-sample attributes for `BAR` overlays.
- [`ScatterVisualAttributes`](scatter_visual_attributes.md): Per-sample attributes for `SCATTER` overlays.
- [`LineVisualAttributes`](line_visual_attributes.md): Per-sample attributes for `LINE` overlays.

## Per-sample visual callbacks (code-driven)

- [`VisualCallbacks`](visual_callbacks.md): Abstract base class of per-sample callbacks.
- [`BarVisualCallbacks`](bar_visual_callbacks.md): Per-sample callbacks for `BAR` overlays.
- [`ScatterVisualCallbacks`](scatter_visual_callbacks.md): Per-sample callbacks for `SCATTER` overlays.
- [`LineVisualCallbacks`](line_visual_callbacks.md): Per-sample callbacks for `LINE` overlays.