#version 330 core
out vec4 FragColor;

uniform vec4 uniColor;
uniform float textureMix;
uniform sampler2D ourTexture;
uniform sampler2D faceTexture;

void main()
{
	// Use Color From VAO
	// FragColor = vec4(appColor, 1.0f);
	
	// Use Texture
	// FragColor = texture(ourTexture, texCoord) * vec4(appColor, 1.0f);

	// Combine 2 textures
	//FragColor = mix(texture(ourTexture, texCoord), texture(faceTexture, texCoord), 0.2);
	//FragColor = mix(texture(ourTexture, texCoord), texture(faceTexture, texCoord), textureMix);

	//FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
	//FragColor = vec4(uniColor);
	// FragColor = vec4(vertexPos, 1.0f);
}
