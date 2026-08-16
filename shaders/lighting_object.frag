#version 330 core
out vec4 FragColor;

in vec3 ResColor;
void main() {
    FragColor = vec4(ResColor, 1.0);
}
