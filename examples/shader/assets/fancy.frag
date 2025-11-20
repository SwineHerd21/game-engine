#version 330 core

in vec2 UV;

out vec4 FragColor;

uniform sampler2D Texture;
uniform float timeSine;

void main() {
	FragColor = texture(Texture, UV) * timeSine / 2.0 + 0.5;
}
