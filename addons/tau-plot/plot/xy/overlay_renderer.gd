## Base class of the renderers that draw the samples of one pane: bars, lines
## and scatter markers.
##
## One instance covers one overlay of one pane. It holds the series of that
## overlay, the config the user gave it, and the styles resolved from it.
##
## An overlay reaches the screen through one of two paths, and the pair
## queue_paint() and on_geometry_settled() covers both:
##  - _draw(), which a queued redraw is enough to reach.
##  - A rebuild against the pane geometry, which exists only while the sort
##    runs. Such an overlay catches up in on_geometry_settled().
@abstract class OverlayRenderer extends Control:

	## Raised when what the overlay shows no longer matches what's expected.
	var dirty: bool = true

	# Resolved TauXYStyle pushed by the plot. Treat as read-only.
	var _xy_style: TauXYStyle = null


	## The config the overlay was built from.
	@abstract func get_config() -> TauPaneOverlayConfig


	## The user style hanging on that config, null when the user cleared it.
	## Read back rather than held, since the user may assign a different one at
	## any moment.
	@abstract func get_user_style() -> TauStyle


	## Runs the style cascade against this renderer and keeps the result. The
	## renderer must be in the tree, since the theme is one of the layers.
	@abstract func resolve_style() -> void


	## Queues the redraw a dirty overlay needs and lowers the flag.
	@abstract func queue_paint() -> void


	## Rebuilds a dirty overlay against the geometry the sort has just settled,
	## and lowers the flag. Runs at the tail of the arrange phase, the one moment the
	## pane geometry is final.
	@abstract func on_geometry_settled() -> void


	## Creates the legend key Control for this overlay. It must set no
	## custom_minimum_size, leaving the key size to the legend.
	@abstract func create_legend_key_control(p_global_series_index: int) -> Control


	## Re-resolves the appearance of a legend key created by
	## create_legend_key_control() and repaints it.
	@abstract func refresh_legend_key_control(p_global_series_index: int, p_control: Control) -> void


	## Updates the hover highlight state. A p_series_id of -1 means the overlay
	## holds no emphasized sample and only dims its own.
	@abstract func set_hover_state(p_active: bool, p_series_id: int, p_sample_index: int, p_color_callback: Callable) -> void


	## Receives the resolved TauXYStyle after cascade resolution.
	func set_resolved_xy_style(p_style: TauXYStyle) -> void:
		_xy_style = p_style
