# TauPlot

A charting and data visualization addon for Godot 4.5+. Bar charts, scatter plots, multi-series graphs, real-time dashboards, and multi-pane (subplot) layouts. Pure GDScript, no external dependencies, interactive, performant, fully themeable.

TauPlot is built for in-game analytics, telemetry overlays, scientific plots, sensor readouts, debug HUDs, financial views, and any tool that needs interactive charts inside a Godot project.

*TauPlot is under active development.* The current release ships with bar and scatter overlays. Line, area, pie, and radar plots are on the [roadmap](#roadmap).

## Features

- **Bar and scatter overlays** can be combined freely in one chart. Bars support grouped, stacked (with optional normalization), and independent layout modes.
- **Godot theme integration** with a three-layer cascade (built-in defaults, Godot theme, code overrides). Every visual property participates in this cascade, so charts match the rest of your UI without per property work.
- **Categorical and continuous axes** with linear or logarithmic scales, axis inversion, and custom tick label formatting.
- **Automatic tick and tick label generation with overlap prevention**, so axes stay readable at any plot size without manual tuning.
- **Real-time streaming** with ring-buffer datasets. The chart redraws incrementally as samples arrive and the oldest points are dropped when the buffer is full.
- **Multi-pane layouts** (also known as subplots) for stacked graphs that share an X axis but use different Y scales.
- **Hover inspection** with configurable tooltip, crosshair, and highlight. Four signals (`sample_hovered`, `sample_hover_exited`, `sample_clicked`, `sample_click_dismissed`) let you react to user interaction.
- **Per-sample styling** through attribute buffers or callbacks. Control color, alpha, marker shape, marker size, outline, and more on a per-sample basis.
- **GPU-accelerated scatter rendering** built on Godot's MultiMesh, with seven built-in marker shapes (circle, square, triangle up/down, diamond, cross, plus) and per-sample shape assignment.
- **Legend** with configurable placement (inside or outside the plot) and flow direction.

## Quick start

Create a scene with a `CenterContainer` root node. Add a `TauPlot` child node named `MyPlot` and give it a `custom_minimum_size` of at least `600 x 400`. Attach the following script to the root node:

```gdscript
extends CenterContainer

func _ready() -> void:
    var dataset := TauPlot.Dataset.make_shared_x_categorical(
        PackedStringArray(["Revenue", "Costs"]),
        PackedStringArray(["Q1", "Q2", "Q3", "Q4"]),
        [
            PackedFloat64Array([120.0, 135.0, 148.0, 160.0]),
            PackedFloat64Array([90.0, 95.0, 100.0, 108.0]),
        ]
    )

    var x_axis := TauAxisConfig.new()
    x_axis.type = TauAxisConfig.Type.CATEGORICAL

    var y_axis := TauAxisConfig.new()
    y_axis.title = "EUR"

    var bar_overlay_config := TauBarConfig.new()

    var pane := TauPaneConfig.new()
    pane.y_left_axis = y_axis
    pane.overlays = [bar_overlay_config]

    var config := TauXYConfig.new()
    config.x_axis = x_axis
    config.panes = [pane]

    var b0 := TauXYSeriesBinding.new()
    b0.series_id = dataset.get_series_id_by_index(0)
    b0.pane_index = 0
    b0.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
    b0.y_axis_id = TauPlot.AxisId.LEFT

    var b1 := TauXYSeriesBinding.new()
    b1.series_id = dataset.get_series_id_by_index(1)
    b1.pane_index = 0
    b1.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
    b1.y_axis_id = TauPlot.AxisId.LEFT

    var bindings: Array[TauXYSeriesBinding] = [b0, b1]

    $MyPlot.title = "Quick Start Example"
    $MyPlot.plot_xy(dataset, config, bindings)
```

This example is available as `examples/quick_start.tscn`.

## Documentation

- [**Getting Started**](https://ze2j.github.io/tau-plot/getting-started/) walks through building your first plot step by step.
- [**API Reference**](https://ze2j.github.io/tau-plot/api/) covers every class, property, enum, and signal.
- The [**demo**](examples/demo.gd) is an advanced example with nine plots showcasing theme customization and per-sample styling through attribute buffers and callbacks.
- The [**tests**](tests/) folder contains self-contained examples of most features.

## Stability

The API may change between releases until version 1.0 is reached. Breaking changes will be documented in the [changelog](CHANGELOG.md). Backward compatibility is taken seriously and disruption will be kept to a minimum, but at this stage correctness and design quality take priority over freezing the API.

## Roadmap

Planned for upcoming releases:

- Line and area overlays for XY plots.
- Interactive legend with click-to-toggle series visibility.
- Pie and radar plot types.

## License

TauPlot is released under the [BSD 3-Clause License](LICENSE).