# TauPlot

A pure GDScript charting addon for Godot 4.5+. No external dependencies. Interactive, performant, and fully themeable.

TauPlot draws XY plots inside any Godot UI. It supports bar and scatter overlays (with more to come), real-time data streaming, multi-pane layouts, per-sample visual control, and deep integration with Godot's theme system.

## Gallery

<p align="center">
  <img src="documentation/docs/assets/hr_diagram.png" alt="HR diagram" />
</p>
<p align="center">
  <img src="documentation/docs/assets/gdp.png" alt="GDP stacked bars" />
</p>
<p align="center">
  <img src="documentation/docs/assets/msft.png" alt="MSFT multi-pane" />
</p>

## Features

- **Bar and scatter overlays** in any combination within a single plot. Bars support grouped, stacked (with optional normalization), and independent modes.
- **Categorical and continuous axes**, with linear or logarithmic scales, axis inversion, tick formatting callbacks, and automatic label overlap prevention.
- **Real-time streaming** with ring-buffer datasets. When the buffer is full, the oldest sample is dropped automatically.
- **Multi-pane layouts** for displaying series with different Y scales side by side (e.g. price above volume).
- **Per-sample styling** through attribute buffers or callbacks. Control color, alpha, marker shape, marker size, outline, and more on a per-sample basis.
- **Godot theme integration** with a three-layer cascade: built-in defaults, Godot theme, code overrides. Every visual property participates in this cascade.
- **Hover inspection** with configurable tooltip, crosshair, and highlight. Four signals (`sample_hovered`, `sample_hover_exited`, `sample_clicked`, `sample_click_dismissed`) let you react to user interaction.
- **GPU-accelerated scatter rendering** using MultiMesh and a custom SDF shader. Seven built-in marker shapes (circle, square, triangle up/down, diamond, cross, plus) with per-sample shape assignment.
- **Legend** with configurable placement (inside or outside the plot) and flow direction.

## Installation

TauPlot requires **Godot 4.5** or later.

### From the Godot Asset Library

1. Open the Godot editor and go to the **AssetLib** tab.
2. Search for **TauPlot**.
3. Click **Download**, then **Install** when prompted.
4. Enable the plugin in **Project > Project Settings > Plugins**.

### Manual

1. Download or clone this repository.
2. Copy the `addons/tau-plot/` folder into your project's `addons/` directory.
3. Enable the plugin in **Project > Project Settings > Plugins**.

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

This example is available as `addons/tau-plot/examples/quick_start.tscn`.

## Documentation

- [**Getting Started**](https://ze2j.github.io/tau-plot/getting-started/) walks through building your first plot step by step.
- [**API Reference**](https://ze2j.github.io/tau-plot/api/) covers every class, property, enum, and signal.
- The [**tests**](addons/tau-plot/tests/) folder contains self-contained examples of most features.

## Stability

The API may change between releases until version 1.0 is reached. Breaking changes will be documented in the [changelog](addons/tau-plot/CHANGELOG.md). Backward compatibility is taken seriously and disruption will be kept to a minimum, but at this stage correctness and design quality take priority over freezing the API.

## Roadmap

Planned for upcoming releases:

- Line and area overlays for XY plots.
- Interactive legend with click-to-toggle series visibility.
- Pie and radar plot types.

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on reporting issues, proposing features, code style, testing, and AI usage policy.

## License

TauPlot is released under the [BSD 3-Clause License](LICENSE).