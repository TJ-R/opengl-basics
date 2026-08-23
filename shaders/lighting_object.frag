#version 330 core

struct Material {
    sampler2D diffuse;
    sampler2D specural;
    float shininess;
};

struct DirLight {
    vec3 direction;
    vec3 ambient;
    vec3 diffuse;
    vec3 specural;
};
uniform DirLight dirLight;

struct PointLight {
    vec3 position;
    vec3 ambient;
    vec3 diffuse;
    vec3 specural;

    float constant;
    float linear;
    float quadratic;
};
#define NR_POINT_LIGHTS 4
uniform PointLight pointLights[NR_POINT_LIGHTS];

struct SpotLight {
    vec3 position;
    vec3 direction;
    vec3 ambient;
    vec3 diffuse;
    vec3 specural;
    float innerCutoff;
    float outerCutoff;
};
uniform SpotLight spotLight;

struct Light {
    // Directional Lighting "sun" only needs direction (rays in a direction on everything)
    // Point Light "light bulb" only needs position also uses attenuation
    // Spotlight "flashlight" needs position and direction. I imagine could also use attenuation

    vec3 position;
    vec3 direction; // Light coming from "infintely far away so position does not matter just direction"
    vec3 ambient;
    vec3 diffuse;
    vec3 specural;

    // For Attenuation Calculation 1 / (Kc + dist * Kl + dist^2 * Kq)
    // float constant;
    // float linear;
    // float quadratic;
    float innerCutOff;
    float outerCutOff;
};

out vec4 FragColor;

in vec3 Normal;
in vec3 FragPos;
in vec2 TexCoords;

uniform vec3 viewPos; // camera position
uniform Material material;
uniform Light light;

vec3 CalcDirLight(DirLight light, vec3 normal, vec3 viewDir) {
    vec3 lightDir = normalize(-light.direction);

    float diff = max(dot(normal, lightDir), 0.0);

    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);

    vec3 ambient = light.ambient * vec3(texture(material.diffuse, TexCoords));
    vec3 diffuse = light.diffuse * vec3(texture(material.diffuse, TexCoords)) * diff;
    vec3 specural = light.specural * vec3(texture(material.specural, TexCoords)) * spec;

    return (ambient + diffuse + specural);
};

vec3 CalcPointLight(PointLight light, vec3 normal, vec3 fragPos, vec3 viewDir) {
    vec3 lightDir = normalize(light.position - fragPos);

    float diff = max(dot(normal, lightDir), 0.0);

    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0) material.shininess);

    float distance = length(light.position - FragPos);
    float attenuation = 1.0 / (light.constant + distance * light.linear
        + (distance * distance) * light.quadratic;


    vec3 ambient = light.ambient * vec3(texture(material.diffuse));
    vec3 diffuse = light.diffuse * diff * vec3(texture(material.diffuse));
    vec3 specural = light.specural * spec * vec3(texture(material.specural));

    ambient *= attenuation;
    diffuse *= attenuation;
    specural *= attenuation;

    return (ambient + diffuse + specural);
};

vec3 CalcSpotlight(SpotLight light, vec3 normal, vec3 fragPos, vec3 viewDir) {
    vec3 lightDir = normalize(light.position - FragPos);
    float theta = dot(lightDirection, normalize(-light.direction));

    float epsilon = light.innerCutoff - light.outerCutoff;
    float intensity = clamp((theta - light.outerCutoff) / epsilon, 0.0, 1.0);

    if (theta > light.outerCutoff) {
        float diff = max(dot(norm, lightDir), 0.0);
        
        float reflectDir = reflect(-lightDir, normal);
        float spec = pow(max(dot(viewDir, reflectDir), 0.0) material.shininess);

        vec3 ambient = light.ambient * vec3(texture(material.diffuse, TexCoords));
        vec3 diffuse = light.diffuse * diff * vec3(texture(material.diffuse, TexCoords));
        vec3 specural = light.specural * spec * vec3(texture(material.specural, TexCoords));

        ambient *= intensity;
        diffuse *= intensity;
        specural *= intensity;

        return (ambient + diffuse + specural);
    } else {
        vec3 ambient = light.ambient * vec3(texture(material.diffuse, TexCoords));
        return ambient;
    }
};

void main() {
    // float distance = length(light.position - FragPos);
    // float attenuation = 1.0 / (light.constant + distance * light.linear 
    //     + (distance * distance) * light.quadratic);

    vec3 norm = normalize(Normal);
    vec3 lightDirection = normalize(light.position - FragPos); 


    // cos(theta) = a dot b where a & b are unit vectors (review dot product formula manipulation)
    float theta = dot(lightDirection, normalize(-light.direction));

    // Calculating intensity 
    /*
        Epsilon is the difference between the cosine values of inner and outer
        Intensity is the difference between the lightDirection cosine value
        and the outer cutoff divided by epsilon
    */
    float epsilon = light.innerCutOff - light.outerCutOff;
    float intensity = clamp((theta - light.outerCutOff) / epsilon, 0.0, 1.0);

    // ambient
    vec3 ambient = light.ambient * vec3(texture(material.diffuse, TexCoords));

    if (theta > light.innerCutOff) {
        // diffuse
        /* Extra Comments on Diffuse */
        // Look up below understanding the diff calculation
        // My understanding it is calculating the angle between the lights
        // direction and the surface normal we are currently checking
        // which determins the strength of diffuse lighting
        // not sure how norm dot lightDir results in the value and why max 
        // is necessary.
        float diff = max(dot(norm, lightDirection), 0.0);
        vec3 diffuse = vec3(texture(material.diffuse, TexCoords)) * diff * light.diffuse;
        //
        // specural
        vec3 viewDir = normalize(viewPos - FragPos);
        vec3 reflectDir = reflect(-lightDirection, norm);

        // 32 is the shininess of the object
        float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
        vec3 specural = vec3(texture(material.specural, TexCoords)) * spec * light.specural;

        diffuse  *= intensity;
        specural *= intensity;

        vec3 resColor = (ambient + diffuse + specural);
        FragColor = vec4(resColor, 1.0);
    } else if (theta > light.outerCutOff) {
        // diffuse
        /* Extra Comments on Diffuse */
        // Look up below understanding the diff calculation
        // My understanding it is calculating the angle between the lights
        // direction and the surface normal we are currently checking
        // which determins the strength of diffuse lighting
        // not sure how norm dot lightDir results in the value and why max 
        // is necessary.
        float diff = max(dot(norm, lightDirection), 0.0);
        vec3 diffuse = vec3(texture(material.diffuse, TexCoords)) * diff * light.diffuse;

        // specural
        vec3 viewDir = normalize(viewPos - FragPos);
        vec3 reflectDir = reflect(-lightDirection, norm);

        // 32 is the shininess of the object
        float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
        vec3 specural = vec3(texture(material.specural, TexCoords)) * spec * light.specural;

        diffuse  *= intensity;
        specural *= intensity;

        vec3 resColor = (ambient + diffuse + specural);

        FragColor = vec4(resColor, 1.0);
    } else {
        vec3 resColor = ambient;
        FragColor = vec4(resColor, 1.0);
    }
}

// Write some light calculation functions here 
