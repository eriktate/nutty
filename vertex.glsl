#version 330 core

layout (location = 0) in vec2 in_pos;
out vec2 pos;

/* const vec2 quadVertices[4] = vec2[4]( */
/* 	vec2(-1.0, 1.0), */
/* 	vec2(1.0, 1.0), */
/* 	vec2(-1.0, -1.0), */
/* 	vec2(1.0, -1.0) */
/* ); */

void main() {
	gl_Position = vec4(in_pos, 0.0, 1.0);
	pos = vec2((in_pos.x + 1)/2, ((in_pos.y * -1) + 1)/2);
}
