#version 330 core
out vec4 FragColor;

uniform vec3 objectColor;
uniform vec3 lightColor;

void main() {
    float ambientStrength = 0.1;
    vec3 ambientLight = lightColor * ambientStrength;

    vec3 resColor = objectColor * ambientLight;
    FragColor = vec4(objectColor * ambientLight, 1.0);
}
