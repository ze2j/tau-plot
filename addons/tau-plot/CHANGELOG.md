# CHANGELOG

## v0.2.0 - 2026-??-??

### Breaking changes

- `ColorBuffer.new()` no longer accepts a default value. Before: `ColorBuffer.new(1024, Color.RED)`. After: `ColorBuffer.new(1024)`. The parameter was accepted but never used, and the four sibling buffer classes never had it, so any call passing it now fails to compile.
- TODO (#30) A color callback returning `ColorBuffer.NO_COLOR` now leaves the sample to the next
  resolution step instead of painting it. Affects `color_callback` on every overlay and
  `outline_color_callback` on scatter. Set the alpha channel to `1` in the callback to
  stay clear of that value, the returned alpha is discarded anyway.
- TODO callbacks parameters raw and plotted
- TODO override detection on assignment (new) vs default value comparisons (old)
- TODO TauXYStyle: series_alpha: float => series_alphas: Array[float] + theme keys
- TODO TauScatterStyle: marker_size_px => marker_sizes_px + theme keys
- TODO TauScatterStyle: hovered_marker_size_px => hovered_marker_sizes_px + theme keys
- TODO: TauPlot.hover_enabled is now true by default

### Added

- TODO line overlay
- `DatasetChange`, the payload of `Dataset.changed`, is now public and documented.
- `StackedNormalization` and `StackedNegativePolicy` added to `TauPlot` namespace.
- TODO Report what the resolved style cannot draw

### Changed

- `TauBarConfig.neighbor_spacing_fraction` now rejects `0.0`. The valid range is `]0.0, 1.0]`, which the property documentation always stated, and the validator now enforces it. Under `BarWidthPolicy.NEIGHBOR_SPACING_FRACTION`, `plot_xy()` reports a validation error and builds no plot when the value is `0.0`. It was previously accepted and drew bars one pixel wide. Negative values were already rejected and are unaffected.
- TODO style changes are now detected by the plot. Calling queue_refresh is no longer necessary and even superflous.
- TODO Enforce at most one overlay of each type per pane. Was documented but not enforced.
- Legend text now resolves its font through the `TauLegend` type variation rather than through the `Label` type.
- A style property assigned a value outside its documented range is now clamped whatever path it arrives by.
- Hovering a pane no longer dims the other panes of the plot. The highlight is scoped to the pane under the cursor.
- A pane is dimmed only while one of its overlays has an emphasized sample.
- The built-in highlight default, used when TauHoverConfig.hover_highlight_callback is unset, multiplies the alpha of a non-emphasized sample by 0.7 instead of forcing it to 0.5.
- The first hit of `sample_hovered` and `sample_clicked` is now the sample closest to the cursor, instead of the first overlay that answered. The `SNAP_TO_POINT` tooltip anchor follows it.
- The X crosshair line is drawn at the hovered X position instead of at the hovered sample.
- The built-in tooltip prints the X value on each line when the hits do not share the same X value.

### Fixed

- The five ring buffer classes, `ColorBuffer`, `Float32Buffer`, `Float64Buffer`, `Int32Buffer` and `StringBuffer`, return a defined constant when `get_value()` is called on an empty buffer or outside `[0; size()[`. Before: an arbitrary stored element, whichever value the ring held at that moment. After: `ColorBuffer.NO_COLOR`, `0.0`, `0.0`, `-1` and `""` respectively. The pushed error is unchanged.
- The five ring buffer classes, `ColorBuffer`, `Float32Buffer`, `Float64Buffer`, `Int32Buffer` and `StringBuffer`, drop the write when `set_value()` is called on an empty buffer or outside `[0; size()[`. Before: the write landed on logical index `0` and silently overwrote the oldest sample. After: nothing is written and the error is pushed. `set_values()` is unaffected, it already validated its range.
- TODO Fix z_order for scatter overlays. Was binding order.
- An overlay with TauPaneOverlayConfig.hoverable = false no longer dims when the cursor enters its pane.
- `X_ALIGNED` hover on a continuous X axis now reports every overlay of the pane. An overlay sampled more coarsely than its neighbours was almost never included, and its `hover_max_distance_px` had no effect.


## v0.1.2 - 2026-05-01

### Added

- Add tests for StackedNormalization (#12)
- Add tests for NaN and INF values (#16)

### Fixed

- Legend key not displayed for scatter overlay with marker_size_policy = DATA_UNITS (#17)
- Negative values in logarithmic scale (#19)
- Hover detection is broken for STACKED bars with normalization enabled (#20)
- Fix copy paste error in getting started examples (#21)


## v0.1.1 - 2026-04-21

### Added

- Add horizontal bars example in getting-started (#5)

### Fixed

- Fix vertical x-axis (#4)
- Fix label overlap prevention (#7)

### Changed

- Documentation cleanup (#8)


## v0.1.0 - 2026-04-14

Initial release of TauPlot, a pure GDScript charting addon for Godot 4.5+.

### Added

- **Bar and scatter overlays** in any combination within a single plot. Bars support grouped, stacked (with optional normalization), and independent modes.
- **Real-time streaming** with ring-buffer datasets.
- **Multi-pane layouts** for displaying series with different Y scales side by side (e.g. price above volume).
- **Per-sample styling** through attribute buffers or callbacks.
- **Godot theme integration** with a three-layer cascade: built-in defaults, Godot theme, code overrides.
- **Hover inspection** with configurable tooltip, crosshair, and highlight.
- **GPU-accelerated scatter rendering** using MultiMesh and a custom SDF shader. Seven built-in marker shapes (circle, square, triangle up/down, diamond, cross, plus) with per-sample shape assignment.
- **Categorical and continuous axes**, with linear or logarithmic scales, axis inversion, tick formatting callbacks, and automatic label overlap prevention.
- **Legend** with configurable placement (inside or outside the plot) and flow direction.
