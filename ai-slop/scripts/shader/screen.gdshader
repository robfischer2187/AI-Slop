shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture;

uniform float scanline_strength = 0.12;
uniform float scanline_count = 600.0;

uniform float glow_strength = 0.35;
uniform float glow_radius = 0.003;

uniform float vignette_strength = 0.25;

uniform float chromatic_aberration = 0.0015;
uniform float flicker_strength = 0.02;

uniform float glitch_intensity = 0.0;
uniform float glitch_time = 0.0;

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	float glitch_wave = sin(uv.y * 40.0 + glitch_time * 20.0) * 0.002 * glitch_intensity;
	float glitch_jump = step(0.98, random(vec2(uv.y, glitch_time))) * 0.05 * glitch_intensity;
	uv.x += glitch_wave + glitch_jump;

	float ca = chromatic_aberration + glitch_intensity * 0.01;

	float r = texture(screen_texture, uv + vec2(ca, 0.0)).r;
	float g = texture(screen_texture, uv).g;
	float b = texture(screen_texture, uv - vec2(ca, 0.0)).b;
	vec3 col = vec3(r, g, b);

	float scan = sin(uv.y * scanline_count) * 0.5 + 0.5;
	col *= mix(1.0, scan, scanline_strength);

	vec3 glow = vec3(0.0);
	float gr = glow_radius;

	glow += texture(screen_texture, uv + vec2(gr, 0.0)).rgb;
	glow += texture(screen_texture, uv - vec2(gr, 0.0)).rgb;
	glow += texture(screen_texture, uv + vec2(0.0, gr)).rgb;
	glow += texture(screen_texture, uv - vec2(0.0, gr)).rgb;
	glow /= 4.0;

	float brightness = dot(col, vec3(0.299, 0.587, 0.114));
	col += glow * glow_strength * brightness;

	float noise = (random(uv + glitch_time) - 0.5) * glitch_intensity * 0.25;
	col += noise;

	vec2 center = uv - vec2(0.5);
	float dist = length(center);
	float vignette = smoothstep(0.8, vignette_strength, dist);
	col *= vignette;

	float flicker = random(vec2(TIME, uv.y)) * flicker_strength;
	col -= flicker;

	COLOR = vec4(col, 1.0);
}