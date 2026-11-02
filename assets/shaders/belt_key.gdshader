shader_type canvas_item;

// Färbt die Magenta-Schlüsselfarbe der Sprites (Gürtel) in die aktuelle Gürtelfarbe um und erlaubt einen Treffer-Blitz.
// Die Helligkeit des Originals bleibt erhalten, damit Falten und Schatten des Gürtels sichtbar bleiben.

uniform bool key_enabled = false;
uniform vec4 belt_color : source_color = vec4(0.94, 0.94, 0.92, 1.0);
uniform float hue_center = 0.8333;
uniform float hue_range = 0.09;
uniform float min_saturation = 0.30;
uniform float min_value = 0.22;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash : hint_range(0.0, 1.0) = 0.0;

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (key_enabled) {
		vec3 hsv = rgb2hsv(tex.rgb);
		float dh = abs(hsv.x - hue_center);
		dh = min(dh, 1.0 - dh);
		float m = (1.0 - smoothstep(hue_range * 0.7, hue_range, dh)) * smoothstep(min_saturation * 0.7, min_saturation, hsv.y) * smoothstep(min_value * 0.7, min_value, hsv.z);
		float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
		float shade = clamp(lum / 0.45, 0.5, 1.3);
		tex.rgb = mix(tex.rgb, belt_color.rgb * shade, m);
	}
	tex.rgb = mix(tex.rgb, flash_color.rgb, flash * tex.a);
	COLOR = tex;
}
