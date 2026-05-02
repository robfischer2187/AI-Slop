shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture;

uniform float scanline_strength = 0.12;
uniform float scanline_count = 600.0;

uniform float glow_strength = 0.15;
uniform float vignette_strength = 0.25;

uniform float chromatic_aberration = 0.0015;
uniform float flicker_strength = 0.02;

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	float r = texture(screen_texture, uv + vec2(chromatic_aberration, 0.0)).r;
	float g = texture(screen_texture, uv).g;
	float b = texture(screen_texture, uv - vec2(chromatic_aberration, 0.0)).b;
	vec3 col = vec3(r, g, b);

	float scan = sin(uv.y * scanline_count) * 0.5 + 0.5;
	col *= mix(1.0, scan, scanline_strength);

	vec2 center = uv - vec2(0.5);
	float dist = length(center);
	float vignette = smoothstep(0.8, vignette_strength, dist);
	col *= vignette;

	vec3 blur = texture(screen_texture, uv + vec2(0.002)).rgb;
	col += blur * glow_strength;

	float flicker = random(vec2(TIME, uv.y)) * flicker_strength;
	col -= flicker;

	COLOR = vec4(col, 1.0);
}