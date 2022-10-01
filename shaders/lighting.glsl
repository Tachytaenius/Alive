uniform vec2 canvasSize;

uniform sampler2D albedoCanvas, lightInfoCanvas;

vec4 effect(vec4 lightColour, sampler2D lightInfluenceTexture, vec2 textureCoords, vec2 windowCoords) {
	// TODO: Cast rays and shadows
	float lightInfluence = Texel(lightInfluenceTexture, textureCoords).r;
	vec3 albedo = Texel(albedoCanvas, windowCoords / canvasSize).rgb;
	vec3 lightInfo = Texel(lightInfoCanvas, windowCoords / canvasSize).rgb;
	lightColour.rgb = min(lightInfo.rgb, lightColour.rgb);
	return vec4(lightColour.rgb * lightInfluence * albedo, 1.0);
}
