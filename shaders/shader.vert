#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aColor;

//out vec4 vertexColor;
//out vec3 appColor;

// Shader Exercise 3
// using this to color based on vertex position
out vec3 vertexPos; 

uniform float hOffset;

void main()
{
	gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
	// vertexColor = vec4(0.5, 0.0, 0.0, 1.0);
	// appColor = aColor;

	// Using swizzling of the set gl_Position
	// just cause
	vertexPos = gl_Position.xyz;
}
