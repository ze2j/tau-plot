# CHANGELOG

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
