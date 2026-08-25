# CHANGELOG

## v0.2.0 - 2026-08-25

### Breaking changes

- `TauXYStyle.series_alpha` is now `series_alphas`, a per-series cycle. Before: `style.series_alpha = 0.85`. After: `style.series_alphas = [0.85]`.
- `TauScatterStyle.marker_size_px` is now `marker_sizes_px`, a per-series cycle. Before: `style.marker_size_px = 10.0`. After: `style.marker_sizes_px = [10.0]`.
- `TauScatterStyle.hovered_marker_size_px` is now `hovered_marker_sizes_px`, a per-series cycle. Before: `style.hovered_marker_size_px = 12.0`. After: `style.hovered_marker_sizes_px = [12.0]`.
- `TauXYStyle.series_colors` is read as a cycle: series `i` takes entry `i % size`. Before: a series past the end of the array pushed an error and was drawn in transparent black, so the array had to be at least as long as the series list.
- A cycle has no un-indexed theme key, so the keys of the properties above are now read one entry at a time. Before: `series_alpha_percent`, `scatter_marker_size_px`, `scatter_hovered_marker_size_px`. After: `series_alpha_percent_0`, `series_alpha_percent_1`, and so on. A theme still setting the old keys loses those properties with no error and no warning.
- A theme setting `series_color_i` keys now replaces the built-in palette instead of extending it. A theme defining `series_color_0` to `series_color_2` before ended up with eight colors, the three from the theme followed by the five built-in ones it did not name. After: the cycle holds those three colors and nothing else.
- The built-in `DEFAULT_*` constants are gone from `TauXYStyle`, `TauPaneStyle`, `TauBarStyle`, `TauScatterStyle`, `TauLegendStyle`, `TauTooltipStyle` and `TauCrosshairStyle`. Each one repeated a value the property already carries. Three survive, because a property names them as its fallback: `TauXYStyle.DEFAULT_SERIES_COLOR`, `TauXYStyle.DEFAULT_SERIES_ALPHA` and `TauScatterStyle.DEFAULT_MARKER_SIZE_PX`. `DEFAULT_SERIES_COLORS`, the whole built-in palette, is not among them. Reading any of the others is now a parse error.
- `SampleHit.y_value` is split into `y_plotted_value` and `y_raw_value`, both in data units. Before: one field, holding the value the sample is drawn at. After: `y_plotted_value` holds that value, `y_raw_value` the dataset value it was built from. The two differ under `STACKED`, and under `FRACTION` or `PERCENT` normalization.
- Every visual callback receives the raw dataset value in its `y_value` parameter. Before: the value the sample is drawn at, so on a stacked bar overlay a callback was handed the cumulative top, scaled when normalization was on. Affects `color_callback`, `alpha_callback` and `style_box_callback` on bars. The scatter callbacks take the same parameter, but a scatter overlay never stacks, so the value they receive is unchanged. The signatures are untouched, so nothing fails and the change is silent.
- The series of an overlay are drawn and stacked in dataset order. Before: the order their bindings were declared in, so `z_order` put the first or last declared series on top rather than the first or last of the dataset, and a stacked overlay laid its bottom layer on the first declared series. After: the dataset decides both, whatever order the bindings come in.
- The built-in tooltip no longer routes its X and Y values through `TauAxisConfig.format_tick_label`. Before: a plot with an axis tick formatter got the same text in its tooltip. After: the tooltip picks its own precision from the domain span and `TauHoverConfig.tooltip_precision_digits`. Set `TauHoverConfig.format_tooltip_text` to take the text back over.
- A style property counts as overridden as soon as it is assigned, whatever the value. Before: the property was compared against its built-in default, so assigning the default left the theme in charge. After: the assignment marks the property and the theme loses it. `null` and the empty array are values like any other. A change made in place is not an assignment and marks nothing, so `style.series_colors[0] = Color.GREEN` and `style.style_box.bg_color = Color.GREEN` are no longer picked up. Assign a new array or a new resource instead. The inspector cannot mark a property either: a value equal to the built-in default is not written to the saved resource.
- `ColorBuffer.new()` no longer accepts a default value. Before: `ColorBuffer.new(1024, Color.RED)`. After: `ColorBuffer.new(1024)`. The parameter was accepted but never used, and the four sibling buffer classes never had it, so any call passing it is now a parse error.
- A color callback returning `ColorBuffer.NO_COLOR` now leaves the sample to the next resolution step instead of painting it. Affects `color_callback` on bars and scatter, and `outline_color_callback` on scatter. Set the alpha channel to `1` in the callback to stay clear of that value, the returned alpha is discarded anyway. (#30)

### Added

- **Line overlay**, configured through `TauLineConfig` and styled through `TauLineStyle`. Series are drawn independently or stacked, with `stacked_normalization` and `stacked_negative_policy`. Interpolation is a per-series cycle over `LINEAR`, `STEP_BEFORE`, `STEP_AFTER`, `STEP_MIDDLE` and `SMOOTH_MONOTONE`. `gap_policy` decides whether an invalid sample breaks the curve or is bridged over. Line widths, hovered line widths and dash lengths are per-series cycles. (#13)
- **Area fills** through `TauLineFill`: down to a baseline, or the band between a curve and the layer below it in a stacked overlay. Flat color or texture, tiled or stretched along the X value, the Y value or the distance from the baseline. A fill merges with the themed one field by field rather than replacing it. A line width of `0` leaves the fill alone, for an area chart with no outline. (#13)
- `TauBarConfig.stacked_negative_policy`. `SKIP_NEGATIVES`, the default, drops negative samples from the stack, which is what stacked bars always did. `DIVERGING` splits each X into an upper stack of positive values and a lower stack of negative values, both anchored at zero. `SIGNED_SUM` is a validation error on bars, since bar geometry cannot dip below a layer without overlapping rectangles.
- `TauStyle`, the base class every style resource now extends. It carries the three layers, what counts as set, cycles, valid ranges and the whole theme key grammar, which the style pages used to repeat one by one.
- `TauXYSeriesBinding.show_in_legend`. Set it to `false` to keep a series out of the legend while still drawing it. Defaults to `true`.
- `SampleHit.contains_pointer` tells whether the cursor is inside the hit zone of the sample rather than merely nearest to it. It is what gates the highlight.
- `DatasetChange`, the payload of `Dataset.changed`, is now public and documented.
- **Bulk reads and fast value getters** on `Dataset` and the five ring buffer classes: `Dataset.get_series_y_slice()`, `Dataset.get_shared_x_numeric_slice()`, `Dataset.get_series_x_numeric_slice()`, and `get_values()` and `get_value_unsafe()` on `ColorBuffer`, `Float32Buffer`, `Float64Buffer`, `Int32Buffer` and `StringBuffer`.
- `StackedNormalization`, `StackedNegativePolicy`, `DatasetChange`, `LineVisualAttributes` and `LineVisualCallbacks` are reachable through the `TauPlot` namespace.
- Resolved styles are checked for consistency once per plot build, and report the property combinations they cannot draw as a warning or an error.

### Changed

- A style property assigned a value outside its documented range is now clamped whatever path it arrives by. A cycle is clamped entry by entry as it is stored.
- A cycle stores a copy of the array assigned to it, so writing into that array afterwards does not reach the style.
- Style changes are detected by the plot, so `TauPlot.queue_refresh()` after a style assignment is no longer necessary. Configuration objects still need it.
- `TauPlot.reset()` no longer hides the title. Before: the title was hidden but `TauPlot.title` kept its value, so setting the same value again did nothing. (#24)
- A theme constant holding a value outside the enum of the property it feeds is reported and replaced by the built-in default. Before: the value reached the renderer, and an unknown marker shape drew whatever the shader made of it.
- A pane holding more than one overlay of the same type is now a validation error. The rule was documented but unenforced.
- A stacked bar overlay and a stacked line overlay sharing one axis of a pane must declare the same `stacked_normalization` and `stacked_negative_policy`. They share a stack, so disagreeing is a validation error.
- Legend text resolves its font and font size through the `TauLegend` theme type variation. Before: `Label/fonts/font` and `Label/font_sizes/font_size` reached the legend. After: `TauLegend/fonts/font` and `TauLegend/font_sizes/font_size` do, and the `Label` keys no longer apply.
- The built-in `font_size` default of `TauLegendStyle` and `TauTooltipStyle` moved from `14` to `16`. Nothing renders differently. Fonts and font sizes are the exception to the three-layer cascade: the theme layer always writes them, falling back to what Godot provides when the theme says nothing, so the built-in value is never reachable. A font property left at `null` draws in the font Godot uses by default.
- A legend flowing vertically sizes every key strip to the widest one, so the series names line up in a column.
- `TauBarConfig.neighbor_spacing_fraction` now rejects `0.0`. The valid range is `]0.0, 1.0]`, which the property documentation always stated. It was previously accepted and drew bars one pixel wide.
- Hovering a pane no longer dims the other panes of the plot. The highlight is scoped to the pane under the cursor.
- A pane is dimmed only while one of its overlays has an emphasized sample.
- The built-in highlight default, used when `TauHoverConfig.hover_highlight_callback` is unset, multiplies the alpha of a non-emphasized sample by 0.7 instead of forcing it to 0.5.
- The first hit of `sample_hovered` and `sample_clicked` is now the sample closest to the cursor, instead of the first overlay that answered. The `SNAP_TO_POINT` tooltip anchor follows it.
- The X crosshair line is drawn at the hovered X position instead of at the hovered sample.
- The built-in tooltip prints the X value on each line when the hits do not share the same X value.
- `Dataset` and the ring buffers behind it have been optimized internally. Reading and writing samples is faster, with no API change and no behavior change.

### Fixed

- Visual attributes could end up on the wrong series. A binding's `visual_attributes` were matched to a series by declaration order rather than by series, so declaring series 1 before series 0 swapped their per-sample buffers. The plot drew without an error, in the wrong colors. (#23)
- A change to `TauHoverConfig.tooltip_style` or `crosshair_style` after `plot_xy()` had no effect, and `queue_refresh()` did not help. Both now re-resolve like every other style. (#25)
- `queue_refresh()` no longer fails when the plot is outside the tree. The pending refresh runs when the plot enters it.
- A pending `queue_refresh()` could run twice. Calling `refresh_now()` or resizing the plot while one was waiting scheduled a second one. (#29)
- Setting `TauPlot.title` or `TauPlot.legend_enabled` after `plot_xy()` did not lay out the plot again. The plot area changed size, but the bars, ticks and axes kept the old geometry and no longer lined up. Both now lay out the plot on the next frame. (#24)
- Changing `TauBarConfig.mode` or one of the stacking properties at runtime and calling `queue_refresh()` now recomputes the Y domain. The change was treated as visual only, so the pane kept the unstacked range and clipped the stack drawn into it.
- The Y domain of a stacked bar overlay holding negative values matches what is drawn. The domain summed every value, negatives included, while the bars skipped them, so the axis reserved room for a total no bar reached.
- The five ring buffer classes, `ColorBuffer`, `Float32Buffer`, `Float64Buffer`, `Int32Buffer` and `StringBuffer`, return a defined constant when `get_value()` is called on an empty buffer or outside `[0; size()[`. Before: an arbitrary stored element, whichever value the ring held at that moment. After: `ColorBuffer.NO_COLOR`, `0.0`, `0.0`, `-1` and `""` respectively. The pushed error is unchanged.
- The five ring buffer classes, `ColorBuffer`, `Float32Buffer`, `Float64Buffer`, `Int32Buffer` and `StringBuffer`, drop the write when `set_value()` is called on an empty buffer or outside `[0; size()[`. Before: the write landed on logical index `0` and silently overwrote the oldest sample. After: nothing is written and the error is pushed. `set_values()` is unaffected, it already validated its range.
- A scatter overlay is clipped to its pane. Markers sitting at the edge of the domain used to spill over the axis and into the neighbouring panes.
- An overlay with `TauPaneOverlayConfig.hoverable = false` no longer dims when the cursor enters its pane.
- `X_ALIGNED` hover on a continuous X axis missed overlays. The plot picks one X value for the whole pane, and an overlay only answered when it held a sample at exactly that X, which an overlay sampled at other X positions almost never did. Its `hover_max_distance_px` was never consulted. Each overlay now answers with the samples at its own X closest to the one picked, as long as that X is within its `hover_max_distance_px`.
- `xy_padding_top` and `xy_padding_bottom` were applied to every pane instead of once to the plot. The gap between two panes is now `xy_pane_gap` alone, as it should always have been.
- Panes with the same `stretch_ratio` came out at different sizes, because the pane drawing the shared X axis paid for the tick marks and tick labels out of its own space. Every pane now gets a drawing area proportional to its `stretch_ratio`, whichever pane carries the axis.


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