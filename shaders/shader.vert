#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aColor;
layout (location = 2) in vec2 aTexCoord;

//out vec4 vertexColor;
out vec3 appColor;
out vec2 texCoord;

uniform float hOffset;
uniform mat4 transform;

void main()
{
	gl_Position = transform * vec4(aPos, 1.0);
	// appColor = aColor;
	texCoord = aTexCoord;

	// vertexColor = vec4(0.5, 0.0, 0.0, 1.0);

	// Using swizzling of the set gl_Position
	// just cause
	// vertexPos = gl_Position.xyz;
}
