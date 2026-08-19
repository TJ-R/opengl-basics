#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aNormal;
layout (location = 2) in vec2 aTexCoord;

out vec3 Normal;
out vec3 FragPos;
out vec2 TexCoords;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
	gl_Position = projection * view * model * vec4(aPos, 1.0f);
	FragPos = vec3(model * vec4(aPos, 1.0)); // World Space Coords

	// Inversion is costly in shader. Should calculate the normal matrix
	// on CPU rather than on the GPU
	// This is for putting a normal in world space
	Normal = mat3(transpose(inverse(model))) * aNormal;
	TexCoords = aTexCoord;
}
