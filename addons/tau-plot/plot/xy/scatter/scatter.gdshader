////////////////////////////////////////////////////////////////////////////////////////////////////
// SCATTER shader
// Renders fill + outline in a single pass using SDF for all marker shapes.
// - COLOR (instance color) = fill_color with alpha pre-applied.
// - INSTANCE_CUSTOM encodes:
//  	.r = outline_color.r
//  	.g = outline_color.g
//  	.b = packed: floor = outline_color_b_quantized, fract = shape_type / 16.0
//  	.a = outline_width_normalized (outline_width_px / size_px)
//
// Shape types decoded from per-instance custom data:
//  	0 = CIRCLE, 1 = SQUARE, 2 = TRIANGLE_UP, 3 = TRIANGLE_DOWN, 4 = DIAMOND, 5 = CROSS, 6 = PLUS
////////////////////////////////////////////////////////////////////////////////////////////////////


shader_type canvas_item;
render_mode blend_mix;

varying vec4 v_instance_custom;
varying float v_shape_type;

void vertex()
{
	v_instance_custom = INSTANCE_CUSTOM;

	// Unpack shape_type from the fractional part of custom.b
	// shape_type is encoded as fract = (shape_type + 0.5) / 16.0
	float packed_b = INSTANCE_CUSTOM.b;
	float fract_b = packed_b - floor(packed_b);
	v_shape_type = floor(fract_b * 16.0);
}

void fragment()
{
	vec2 p = UV - 0.5;
	float d = 0.0;

	int shape = int(v_shape_type + 0.5);

	if (shape == 0)
	{
		// Circle: radius 0.5
		d = length(p) - 0.5;
	}
	else if (shape == 1)
	{
		// Square: half-side 0.5
		d = max(abs(p.x), abs(p.y)) - 0.5;
	}
	else if (shape == 2)
	{
		// Triangle up: vertices (0,-0.5), (0.5,0.5), (-0.5,0.5)
		float d0 = p.x * 0.89442719 + (p.y + 0.5) * (-0.44721359);
		float d1 = p.y - 0.5;
		float d2 = (p.x + 0.5) * (-0.89442719) + (p.y - 0.5) * (-0.44721359);
		d = max(d0, max(d1, d2));
	}
	else if (shape == 3)
	{
		// Triangle down: vertices (0,0.5), (-0.5,-0.5), (0.5,-0.5) CCW
		float d0 = p.x * (-0.89442719) + (p.y - 0.5) * 0.44721359;
		float d1 = -(p.y + 0.5);
		float d2 = (p.x - 0.5) * 0.89442719 + (p.y + 0.5) * 0.44721359;
		d = max(d0, max(d1, d2));
	}
	else if (shape == 4)
	{
		// Diamond: abs(x) + abs(y) <= 0.5
		d = abs(p.x) + abs(p.y) - 0.5;
	}
	else if (shape == 5)
	{
		// Cross (X shape): union of two thin rotated rectangles
		// Rotate p by 45 degrees
		float s = 0.70710678; // sin(45) = cos(45)
		float rx = abs(p.x * s + p.y * s);
		float ry = abs(-p.x * s + p.y * s);
		// Two bars of half-width 0.15 and half-length 0.5
		float bar_half_width = 0.15;
		float d1 = max(rx - bar_half_width, ry - 0.5);
		float d2 = max(ry - bar_half_width, rx - 0.5);
		d = min(d1, d2);
	}
	else if (shape == 6)
	{
		// Plus (+): union of horizontal and vertical bars
		float bar_half_width = 0.15;
		float d1 = max(abs(p.x) - 0.5, abs(p.y) - bar_half_width);
		float d2 = max(abs(p.x) - bar_half_width, abs(p.y) - 0.5);
		d = min(d1, d2);
	}
	else
	{
		discard;
	}

	// Recover outline color: .r is direct, .g is direct, .b is floor of packed value
	float outline_b = floor(v_instance_custom.b) / 255.0;
	float outline_w = v_instance_custom.a;
	vec4 fill_col = COLOR;
	vec4 outline_col = vec4(v_instance_custom.r, v_instance_custom.g, outline_b, fill_col.a);

	// Anti-aliasing width in SDF units
	float aa = fwidth(d) * 1.2;

	// Outside the shape boundary: fully transparent
	float shape_mask = 1.0 - smoothstep(-aa, aa, d);
	if (shape_mask < 0.002)
		discard;

	// Inside: determine fill vs outline
	vec4 result;
	if (outline_w > 0.001)
	{
		float fill_edge = -outline_w;
		float fill_mask = 1.0 - smoothstep(fill_edge - aa, fill_edge + aa, d);
		result = mix(outline_col, fill_col, fill_mask);
	}
	else
	{
		result = fill_col;
	}

	COLOR = vec4(result.rgb, result.a * shape_mask);
}