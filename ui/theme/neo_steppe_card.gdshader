shader_type canvas_item;

// Bozkır Modernizmi Obsidian / Glass Card Shader
// Renders deep obsidian-charcoal glass backing, subtle frosted steppe micro-grain,
// 1-2px weathered bronze perimeter frame, and geometric Tamga corner brackets.

uniform vec4 base_obsidian_color : source_color = vec4(0.055, 0.063, 0.078, 0.92);
uniform vec4 charcoal_top_color : source_color = vec4(0.110, 0.125, 0.149, 0.88);
uniform vec4 bronze_border_color : source_color = vec4(0.620, 0.478, 0.275, 0.95);
uniform vec4 semantic_accent_color : source_color = vec4(0.180, 0.686, 0.541, 1.0);
uniform float border_px : hint_range(1.0, 2.5) = 1.5;
uniform float tamga_corner_len : hint_range(4.0, 20.0) = 9.0;
uniform float glass_sheen : hint_range(0.0, 1.0) = 0.20;
uniform float accent_glow : hint_range(0.0, 1.0) = 0.24;
uniform float alert_pulse : hint_range(0.0, 1.0) = 0.0;
uniform vec2 panel_size = vec2(240.0, 64.0);

float hash_grain(vec2 p) {
	vec2 q = fract(p * vec2(123.34, 456.21));
	q += dot(q, q + 45.32);
	return fract(q.x * q.y);
}

void fragment() {
	vec2 safe_size = max(panel_size, vec2(16.0));
	vec2 px = UV * safe_size;

	// Vertical obsidian-to-charcoal glass gradient + diagonal frosted reflection
	float top_mix = pow(1.0 - UV.y, 1.35);
	vec4 glass_col = mix(base_obsidian_color, charcoal_top_color, top_mix * 0.72);
	float sheen_band = exp(-pow((UV.x * 0.65 + UV.y * 0.35 - 0.28) * 5.2, 2.0));
	glass_col.rgb += vec3(0.11, 0.12, 0.14) * sheen_band * glass_sheen;

	// Subtle obsidian mineral micro-grain
	float grain = (hash_grain(floor(px)) - 0.5) * 0.018;
	glass_col.rgb = max(glass_col.rgb + grain, vec3(0.0));

	// Edge distance in pixels for razor-sharp 1-2px perimeter + geometric Tamga corners
	float dist_left = px.x;
	float dist_right = safe_size.x - px.x;
	float dist_top = px.y;
	float dist_bottom = safe_size.y - px.y;
	float edge_dist = min(min(dist_left, dist_right), min(dist_top, dist_bottom));

	// Top edge hairline accent glow + optional alert breathing pulse
	float pulse_wave = 0.5 + 0.5 * sin(TIME * 3.6);
	float live_pulse = alert_pulse * (0.45 + 0.55 * pulse_wave);
	float top_glow = exp(-dist_top * 0.16) * (accent_glow * 0.32 + live_pulse * 0.42);
	glass_col.rgb = mix(glass_col.rgb, semantic_accent_color.rgb, clamp(top_glow, 0.0, 0.65));

	// Outer 1.5px weathered bronze frame
	float border_mask = 1.0 - smoothstep(border_px - 0.35, border_px + 0.35, edge_dist);

	// Geometric Tamga L-brackets at all 4 corners + top center Tamga keystone
	float dx_edge = min(dist_left, dist_right);
	float dy_edge = min(dist_top, dist_bottom);
	float in_corner_arm = step(dx_edge, tamga_corner_len) * step(dy_edge, border_px + 1.0)
		+ step(dy_edge, tamga_corner_len) * step(dx_edge, border_px + 1.0);
	float corner_mask = clamp(in_corner_arm, 0.0, 1.0);
	float top_center_tick = step(abs(px.x - safe_size.x * 0.5), 14.0) * step(dist_top, border_px + 1.2);

	vec3 frame_rgb = mix(bronze_border_color.rgb, semantic_accent_color.rgb, 0.32 + live_pulse * 0.45);
	vec3 corner_rgb = mix(bronze_border_color.rgb * 1.18, semantic_accent_color.rgb, 0.55);

	vec3 out_rgb = mix(glass_col.rgb, frame_rgb, border_mask * 0.78);
	out_rgb = mix(out_rgb, corner_rgb, max(corner_mask, top_center_tick) * 0.90);

	float out_alpha = max(glass_col.a, border_mask * bronze_border_color.a) * COLOR.a;
	COLOR = vec4(out_rgb, clamp(out_alpha, 0.0, 1.0));
}
