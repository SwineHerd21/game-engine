#version 330 core

out vec4 FragColor;

in vec3 vertexColor;

uniform float timeSine;

void main() {
	FragColor = vec4(vertexColor * (timeSine / 2.0 + 0.5), 1.0);
}
