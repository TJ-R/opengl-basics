#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aNormal;

out vec3 Normal;
out vec3 FragPos;
out vec3 LightPos;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform vec3 lightPos;

void main()
{
	gl_Position = projection * view * model * vec4(aPos, 1.0f);

	// Fragment position based on the camera (eye)
	FragPos = vec3(view * model * vec4(aPos, 1.0));

	LightPos = vec3(view * vec4(lightPos, 1.0));

	// Inversion is costly in shader. Should calculate the normal matrix
	// on CPU rather than on the GPU
	// This is for putting a normal in view (eye) space
	Normal = mat3(transpose(inverse(view * model))) * aNormal;
}
