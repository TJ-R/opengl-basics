#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aNormal;

out vec3 ResColor;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

uniform vec3 objectColor;
uniform vec3 lightColor;
uniform vec3 lightPos;
uniform vec3 viewPos; // camera position

void main()
{
	gl_Position = projection * view * model * vec4(aPos, 1.0f);

	// Inversion is costly in shader. Should calculate the normal matrix
	// on CPU rather than on the GPU
	// This is for putting a normal in world space
	vec3 normal = mat3(transpose(inverse(model))) * aNormal;

    float ambientStrength = 0.1;
    float specuralStrength = 1.0;

    vec3 ambientLight = lightColor * ambientStrength;

    vec3 norm = normalize(normal);
    vec3 lightDirection = normalize(lightPos - aPos); 

    // Look up below understanding the diff calculation
    // My understanding it is calculating the angle between the lights
    // direction and the surface normal we are currently checking
    // which determins the strength of diffuse lighting
    // not sure how norm dot lightDir results in the value and why max 
    // is necessary.
    float diff = max(dot(norm, lightDirection), 0.0);
    vec3 diffuse = diff * lightColor;

    // Calc spectral
    vec3 viewDir = normalize(viewPos - aPos);
    vec3 reflectDir = reflect(-lightDirection, norm);

    // 32 is the shinyness of the object
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32);
    vec3 specural = specuralStrength * spec * lightColor;

    ResColor = objectColor * (ambientLight + diffuse + specural);
}
