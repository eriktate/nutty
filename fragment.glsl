#version 330 core

in vec2 pos;

out vec4 frag_color;

uniform sampler2D tex;

void main() {
	vec4 color = texture(tex, pos);
	frag_color = vec4(color.r, color.r, color.r, color.a);
}
