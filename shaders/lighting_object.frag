#version 330 core
out vec4 FragColor;

in vec3 Normal;
in vec3 FragPos;

uniform vec3 objectColor;
uniform vec3 lightColor;
uniform vec3 lightPos;
uniform vec3 viewPos; // camera position

void main() {
    float ambientStrength = 0.1;
    float specuralStrength = 0.5;

    vec3 ambientLight = lightColor * ambientStrength;

    vec3 norm = normalize(Normal);
    vec3 lightDirection = normalize(lightPos - FragPos); 

    // Look up below understanding the diff calculation
    // My understanding it is calculating the angle between the lights
    // direction and the surface normal we are currently checking
    // which determins the strength of diffuse lighting
    // not sure how norm dot lightDir results in the value and why max 
    // is necessary.
    float diff = max(dot(norm, lightDirection), 0.0);
    vec3 diffuse = diff * lightColor;

    // Calc spectral
    vec3 viewDir = normalize(viewPos - FragPos);
    vec3 reflectDir = reflect(-lightDirection, norm);

    // 32 is the shinyness of the object
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32);
    vec3 specural = specuralStrength * spec * lightColor;

    vec3 resColor = objectColor * (ambientLight + diffuse + specural);
    FragColor = vec4(resColor, 1.0);
}
