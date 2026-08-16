#version 330 core

struct Material {
    vec3 ambient;
    vec3 diffuse;
    vec3 specural;
    float shininess;
};

out vec4 FragColor;

in vec3 Normal;
in vec3 FragPos;

uniform vec3 objectColor;
uniform vec3 lightColor;
uniform vec3 lightPos;
uniform vec3 viewPos; // camera position
uniform Material material;

void main() {
    // ambient
    vec3 ambient = lightColor * material.ambient;

    // diffuse
    /* Extra Comments on Diffuse */
    // Look up below understanding the diff calculation
    // My understanding it is calculating the angle between the lights
    // direction and the surface normal we are currently checking
    // which determins the strength of diffuse lighting
    // not sure how norm dot lightDir results in the value and why max 
    // is necessary.
    vec3 norm = normalize(Normal);
    vec3 lightDirection = normalize(lightPos - FragPos); 
    float diff = max(dot(norm, lightDirection), 0.0);
    vec3 diffuse = (material.diffuse * diff) * lightColor;

    // specural
    vec3 viewDir = normalize(viewPos - FragPos);
    vec3 reflectDir = reflect(-lightDirection, norm);

    // 32 is the shininess of the object
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
    vec3 specural = (material.specural * spec) * lightColor;

    vec3 resColor = ambient + diffuse + specural;
    FragColor = vec4(resColor, 1.0);
}
