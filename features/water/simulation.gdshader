shader_type canvas_item;

uniform sampler2D sim_tex : filter_nearest, hint_default_transparent;
uniform sampler2D col_tex : filter_nearest, hint_default_transparent;
uniform sampler2D ter_tex : filter_nearest, hint_default_transparent;

const float phase = 0.225;
const float attenuation = 0.999;
const float deltaUV = 1.0;

void fragment() {
	float dv = 1.0 / 512.0;
	float du = 1.0 / 512.0;
	vec3 duv = vec3(du, dv, 0) * deltaUV;

	vec3 c = texture(sim_tex, UV).rgb;

	float p = (2.0 * c.r - c.g + phase * (
		texture(sim_tex, UV - duv.zy).r +
		texture(sim_tex, UV + duv.zy).r +
		texture(sim_tex, UV - duv.xz).r +
		texture(sim_tex, UV + duv.xz).r - 4.0 * c.r)) * attenuation;

	vec2 col_uv = vec2(UV.x, 1.0 - UV.y);
	float col = texture(col_tex, col_uv).r;
	float prevCol = texture(sim_tex, UV).b;
  float ter = texture(ter_tex, UV).g;
  
	if (col > 0.0 && prevCol == 0.0) {
		p += col * 0.5;
	} else if

	(prevCol > 0.0 && col == 0.0) {
		p -= prevCol * 1.5;
	} else if
  
  (ter > 0.0) {
    p = p * -2.0;
  }

	COLOR = vec4(p, c.r, col, 1.0);
}
