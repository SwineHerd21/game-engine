#version 330 core

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec3 aColor;

out vec3 vertexColor;

uniform vec3 values[3];

void main() {
	gl_Position = vec4(aPos, 1.0);
	vertexColor = vec3(values[0].x, values[1].y, values[2].z);
}

