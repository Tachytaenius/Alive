uniform vec2 canvasSize;
uniform float revealDepth;
uniform float forceNonRevealMinDepth;

uniform sampler2D lightFilterCanvas;
uniform vec2 lightOrigin;
uniform bool isView;
uniform float crushStart;
uniform float power;

vec4 effect(vec4 colour, sampler2D texture, vec2 textureCoords, vec2 windowCoords) {
	vec3 lightColour = colour.rgb;
	vec2 direction = normalize(windowCoords - lightOrigin);
	// Filter light colour
	float len = distance(windowCoords, lightOrigin);
	bool hitWall = false;
	float wallPenetration = 0.0;
	bool forceNonReveal = false;
	float lastDistance = 0.0;
	for (int i = 0; i < len; i++) {
		vec2 currentPosition = lightOrigin + direction * i;
		vec4 lightFilterColour = Texel(lightFilterCanvas, currentPosition / canvasSize);
		lightColour = min(lightFilterColour.rgb, lightColour);
		hitWall = lightFilterColour.a != 0.0 ? true : hitWall;
		float dist = isView ? max(i, crushStart * pow(i / crushStart, power)) : i; // If we are working on the player view we want the distance if the canvas was un-crushed. Assume centre of crush effect maps to lightOrigin. If this is a normal light in the pre-crush canvas system, distance is 1:1 with pixel distance traversed
		float distanceTraversed = dist - lastDistance;
		wallPenetration += hitWall ? distanceTraversed : 0.0; // Only increment penetration if we've hit a wall
		forceNonReveal = hitWall && lightFilterColour.a == 0.0 && wallPenetration >= forceNonRevealMinDepth ? true : forceNonReveal; // Force shadow if we leave the wall again before wallPenetration reaches revealDepth, but only if we have already penetrated a forceNonRevealMinDepth into the wall (the second check is to avoid fragment being erroneously in shadow)
		lastDistance = dist;
	}
	// Ignore shadow if in revealed portion of wall
	if (wallPenetration < revealDepth && !forceNonReveal) {
		lightColour = colour.rgb;
	}
	// Return values
	float lightInfluence = Texel(texture, textureCoords).r; // Falloff
	return vec4(lightColour * lightInfluence, 1.0);
}
