uniform vec2 canvasSize;
uniform float revealDepth;

uniform sampler2D albedoCanvas, lightInfoCanvas;

uniform vec2 lightOrigin;

vec4 effect(vec4 colour, sampler2D texture, vec2 textureCoords, vec2 windowCoords) {
	vec3 lightColour = colour.rgb;
	vec2 direction = normalize(windowCoords - lightOrigin);
	// Filter light colour
	float len = distance(windowCoords, lightOrigin);
	bool hitWall = false;
	float wallPenetration = 0.0;
	bool forceNonReveal = false;
	for (int i = 0; i < len; i++) {
		vec2 currentPosition = lightOrigin + direction * i;
		vec4 lightInfoColour = Texel(lightInfoCanvas, currentPosition / canvasSize);
		lightColour = min(lightInfoColour.rgb, lightColour);
		if (lightColour == vec3(0.0) && wallPenetration >= revealDepth) {
			discard; // Optimisation
		}
		hitWall = lightInfoColour.a != 0.0 ? true : hitWall;
		wallPenetration += hitWall ? 1.0 : 0.0; // Only increment penetration if we've hit a wall
		forceNonReveal = hitWall && lightInfoColour.a == 0.0 ? true : forceNonReveal; // Force shadow if we leave the wall again before wallPenetration reaches revealDepth
	}
	if (wallPenetration < revealDepth && !forceNonReveal) {
		lightColour = colour.rgb;
	}
	float lightInfluence = Texel(texture, textureCoords).r; // Falloff
	vec3 albedo = Texel(albedoCanvas, windowCoords / canvasSize).rgb;
	return vec4(lightColour * lightInfluence * albedo, 1.0);
}
