shader_type canvas_item;

// Bozkır Modernizmi Tactical Pill & Crisis Chip Shader
// Provides frosted obsidian base, weathered bronze bevel highlight, and urgent sweep pulse.

uniform vec4 base_fill_color : source_color = vec4(0.075, 0.086, 0.106, 0.90);
uniform vec4 accent_rim_color : source_color = vec4(0.831, 0.667, 0.361, 1.0);
uniform float active_weight : hint_range(0.0, 1.0) = 0.0;
uniform float urgent_pulse : hint_range(0.0, 1.0) = 0.0;
uniform vec2 pill_size = vec2(140.0, 34.0);

void fragment() {
	vec2 safe_size = max(pill_size, vec2(12.0));
	vec2 px = UV * safe_size;

	float edge_x = min(px.x, safe_size.x - px.x);
	float edge_y = min(px.y, safe_size.y - px.y);
	float rim = 1.0 - smoothstep(1.0, 2.0, min(edge_x, edge_y));

	float sheen_pos = fract(TIME * 0.22);
	float sweep = exp(-pow((UV.x - sheen_pos) * 7.5, 2.0)) * urgent_pulse * 0.28;
	float breath = (0.5 + 0.5 * sin(TIME * 4.2)) * urgent_pulse;

	vec3 fill_rgb = mix(base_fill_color.rgb, accent_rim_color.rgb, active_weight * 0.18 + breath * 0.20 + sweep);
	float left_marker = step(px.x, 3.0) * max(active_weight, urgent_pulse);
	vec3 final_rgb = mix(fill_rgb, accent_rim_color.rgb, clamp(rim * (0.45 + 0.55 * max(active_weight, breath)) + left_marker, 0.0, 1.0));

	float final_alpha = max(base_fill_color.a, rim * 0.95) * COLOR.a;
	COLOR = vec4(final_rgb, clamp(final_alpha, 0.0, 1.0));
}
