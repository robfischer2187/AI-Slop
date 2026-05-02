shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture;

uniform float vignette_strength = 1.5;
uniform float vignette_pulse = 0.15;
uniform float pulse_speed = 0.9;

uniform float darkness = 0.4;
uniform float contrast = 1.15;

uniform float grain_strength = 0.015;
uniform float chromatic_strength = 0.001;

uniform float flicker_chance = 0.02;

uniform vec3 warm_tint = vec3(1.0, 0.95, 0.85);
uniform vec3 cold_tint = vec3(0.85, 0.88, 0.9);

uniform float tint_strength = 0.35;

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 center = uv - vec2(0.5);

	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
	float vignette_dynamic = vignette_strength + pulse * vignette_pulse;

	float dist = length(center);

	float vignette = smoothstep(0.1, 0.75, dist);
	vignette = pow(vignette, 6.0);

	float edge_darkness = vignette * vignette_dynamic;

	float grain = random(uv * vec2(320.0, 200.0) + TIME);
	grain = (grain - 0.5) * grain_strength;

	vec2 red_offset = vec2(chromatic_strength, 0.0);
	vec2 blue_offset = vec2(-chromatic_strength, 0.0);

	float r = texture(screen_texture, uv + red_offset).r;
	float g = texture(screen_texture, uv).g;
	float b = texture(screen_texture, uv + blue_offset).b;

	vec4 color = vec4(r, g, b, 1.0);

	vec3 dynamic_tint = mix(warm_tint, cold_tint, vignette);
	color.rgb = mix(color.rgb, color.rgb * dynamic_tint, tint_strength);

	color.rgb = (color.rgb - 0.5) * contrast + 0.5;

	color.rgb = mix(color.rgb, color.rgb * 0.15, darkness);

	color.rgb = mix(color.rgb, vec3(0.0), edge_darkness);

	color.rgb *= (1.0 - edge_darkness * 0.5);

	float top_dark = smoothstep(0.0, 0.6, uv.y);
	color.rgb *= mix(1.0, 0.7, top_dark);

	color.rgb += grain;

	float flicker = step(1.0 - flicker_chance, random(vec2(TIME * 3.0, 0.0)));
	if (flicker > 0.0) {
		color.rgb *= 0.8;
	}

	COLOR = color;
}