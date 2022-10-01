uniform vec2 canvasSize;

uniform sampler2D albedoCanvas, lightInfoCanvas;

uniform vec2 lightOrigin;

vec4 effect(vec4 colour, sampler2D texture, vec2 textureCoords, vec2 windowCoords) {
	vec3 lightColour = colour.rgb;
	vec2 direction = normalize(windowCoords - lightOrigin);
	// Filter light colour
	float len = distance(windowCoords, lightOrigin);
	for (int i = 0; i < len; i++) {
		vec2 currentPosition = lightOrigin + direction * i;
		vec4 lightInfoColour = Texel(lightInfoCanvas, currentPosition / canvasSize);
		lightColour = min(lightInfoColour.rgb, lightColour);
		if (lightColour == vec3(0.0)) {
			discard; // Optimisation
		}
	}
	float lightInfluence = Texel(texture, textureCoords).r; // Falloff
	vec3 albedo = Texel(albedoCanvas, windowCoords / canvasSize).rgb;
	return vec4(lightColour * lightInfluence * albedo, 1.0);
}
