#version 330 core

struct Material {
    sampler2D diffuse;
    sampler2D specural;
    sampler2D emission;
    float shininess;
};

struct Light {
    vec3 position;
    vec3 ambient;
    vec3 diffuse;
    vec3 specural;
};

out vec4 FragColor;

in vec3 Normal;
in vec3 FragPos;
in vec2 TexCoords;

uniform vec3 viewPos; // camera position
uniform Material material;
uniform Light light;

void main() {
    // ambient
    vec3 ambient = light.ambient * vec3(texture(material.diffuse, TexCoords));
    
    // So sign makes it so if it is above 0 then returns 1, 0 returns 0,
    // an below 0 returns -1. Since my specural map only has true black
    // in center this should work properly
    vec3 emission = (1.0 - sign(vec3(texture(material.specural, TexCoords)))) * vec3(texture(material.emission, TexCoords));

    // diffuse
    /* Extra Comments on Diffuse */
    // Look up below understanding the diff calculation
    // My understanding it is calculating the angle between the lights
    // direction and the surface normal we are currently checking
    // which determins the strength of diffuse lighting
    // not sure how norm dot lightDir results in the value and why max 
    // is necessary.
    vec3 norm = normalize(Normal);
    vec3 lightDirection = normalize(light.position - FragPos); 
    float diff = max(dot(norm, lightDirection), 0.0);
    vec3 diffuse = vec3(texture(material.diffuse, TexCoords)) * diff * light.diffuse;
    //
    // specural
    vec3 viewDir = normalize(viewPos - FragPos);
    vec3 reflectDir = reflect(-lightDirection, norm);

    // 32 is the shininess of the object
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
    vec3 specural = vec3(texture(material.specural, TexCoords)) * spec * light.specural;

    vec3 resColor = ambient + diffuse + specural + emission;
    FragColor = vec4(resColor, 1.0);
}
