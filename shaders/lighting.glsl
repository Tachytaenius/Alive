uniform vec2 canvasSize;

uniform sampler2D albedoCanvas;

vec4 effect(vec4 lightColour, sampler2D lightInfluenceTexture, vec2 textureCoords, vec2 windowCoords) {
	float lightInfluence = Texel(lightInfluenceTexture, textureCoords).r;
	vec3 albedo = Texel(albedoCanvas, windowCoords / canvasSize).rgb;
	return vec4(lightColour.rgb * lightInfluence * albedo, 1.0);
}
