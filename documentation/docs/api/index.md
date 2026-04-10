# API Reference

This section documents the public classes of TauPlot.

## Entry point

- [`TauPlot`](tau_plot.md): The plot node.

## Data Classes

- [`Dataset`](dataset.md): Data container holding series and samples.
- [`ColorBuffer`](color_buffer.md): Per-sample `Color` buffer.
- [`Float32Buffer`](float32_buffer.md): Per-sample `float32` buffer.
- [`Float64Buffer`](float64_buffer.md): Per-sample `float64` buffer.
- [`Int32Buffer`](int32_buffer.md): Per-sample `int32` buffer.
- [`StringBuffer`](string_buffer.md): Per-sample `String` buffer.

## Series Binding

- [`TauXYSeriesBinding`](xy_series_binding.md): Maps a dataset series to a pane, overlay, and y axis.

## Plot configuration

- [`TauXYConfig`](xy_config.md): Top-level XY plot configuration.
- [`TauPaneConfig`](pane_config.md): Pane configuration.
- [`TauAxisConfig`](axis_config.md): Axis configuration.
- [`TauPaneOverlayConfig`](pane_overlay_config.md): Base class of overlay configurations.
- [`TauBarConfig`](bar_config.md): Bar-specific rendering configuration, extends [`TauPaneOverlayConfig`](pane_overlay_config.md)
- [`TauScatterConfig`](scatter_config.md): Scatter-specific rendering configuration, extends [`TauPaneOverlayConfig`](pane_overlay_config.md)

## Additional configuration

- [`TauLegendConfig`](legend_config.md): Legend configuration including position, flow direction, and style.
- [`TauGridLineConfig`](grid_line_config.md): Grid line configuration.
- [`TauHoverConfig`](hover_config.md): Hover configuration including highlight, tooltip and crosshair.
- [`SampleHit`](sample_hit.md): Read-only data object produced by hovering inspection system.

## Style resources

- [`TauXYStyle`](xy_style.md): Visual appearance of the plot.
- [`TauPaneStyle`](pane_style.md): Visual appearance of a pane.
- [`TauBarStyle`](bar_style.md): Visual appearance of `BAR` overlays.
- [`TauScatterStyle`](scatter_style.md): Visual appearance of `SCATTER` overlays. 
- [`TauLegendStyle`](legend_style.md): Visual appearance of the legend.
- [`TauTooltipStyle`](tooltip_style.md): Tooltip visual style.
- [`TauCrosshairStyle`](crosshair_style.md): Crosshair visual style.

## Per-sample visual attributes (data-driven)

- [`VisualAttributes`](visual_attributes.md): Per-sample attributes base class.
- [`BarVisualAttributes`](bar_visual_attributes.md): Per-sample attributes for `BAR` overlays.
- [`ScatterVisualAttributes`](scatter_visual_attributes.md): Per-sample attributes for `SCATTER` overlays.

## Per-sample visual callbacks (code-driven)

- [`VisualCallbacks`](visual_callbacks.md): Per-sample callbacks base class.
- [`BarVisualCallbacks`](bar_visual_callbacks.md): Per-sample callbacks for `BAR` overlays.
- [`ScatterVisualCallbacks`](scatter_visual_callbacks.md): Per-sample callbacks for `SCATTER` overlays.