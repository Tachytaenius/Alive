uniform vec2 windowSize;

vec4 effect(vec4 colour, Image image, vec2 textureCoords, vec2 windowCoords) {
	vec2 x = vec2(1 / windowSize.x, 0);
	vec2 y = vec2(0, 1 / windowSize.y);
	float aboveAlpha = Texel(image, textureCoords - y).a;
	float belowAlpha = Texel(image, textureCoords + y).a;
	float leftAlpha = Texel(image, textureCoords - x).a;
	float rightAlpha = Texel(image, textureCoords + x).a;
	float neighbourAlpha = aboveAlpha + belowAlpha + leftAlpha + rightAlpha;
	vec4 returnColour = Texel(image, textureCoords);
	if (neighbourAlpha != 0 && returnColour.a == 0) returnColour.a = 1;
	return colour * returnColour;
}
