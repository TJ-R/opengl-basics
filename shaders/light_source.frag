#version 330 core

out vec4 FragColor;

uniform vec3 ambient;


void main() {
    // ambient
    vec3 ambient = 1.0 * ambient;

    vec3 resColor = ambient;
    FragColor = vec4(resColor, 1.0);
}
