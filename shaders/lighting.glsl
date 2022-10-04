uniform vec2 canvasSize;
uniform float revealDepth;
uniform float forceNonRevealMinDepth;

uniform sampler2D lightInfoCanvas;

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
		forceNonReveal = hitWall && lightInfoColour.a == 0.0 && wallPenetration >= forceNonRevealMinDepth ? true : forceNonReveal; // Force shadow if we leave the wall again before wallPenetration reaches revealDepth, but only if we have already penetrated a forceNonRevealMinDepth into the wall (the second check is to avoid fragment being erroneously in shadow)
	}
	// Ignore shadow if in revealed portion of wall
	if (wallPenetration < revealDepth && !forceNonReveal) {
		lightColour = colour.rgb;
	}
	// Return values
	float lightInfluence = Texel(texture, textureCoords).r; // Falloff
	return vec4(lightColour * lightInfluence, 1.0);
}
