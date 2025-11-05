#version 330 core

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec3 aColor;

out vec3 vertexColor;

uniform float values[3];
uniform float timeSine;

void main() {
	gl_Position = vec4(aPos.x + values[0] * timeSine, aPos.y + values[1] * timeSine, aPos.z + values[2] * timeSine, 1.0);
	vertexColor = aColor;
}

