#version 330 core

in vec3 vertexColor;

out vec4 FragColor;

uniform float timeSine;

void main() {
	FragColor = vec4(vertexColor.zxy * (timeSine / 2.0 + 0.5), 1.0);
}
