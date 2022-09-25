uniform vec2 inputCanvasSize;
uniform vec2 outputCanvasSize;
uniform vec2 crushCentre;
uniform float crushStart;
uniform float crushEnd;
uniform float power;

vec4 sampleInputCanvas(sampler2D texture, vec2 fragmentPosition) {
	vec2 crushCentreToPosition = fragmentPosition - crushCentre;
	float fragmentDistance = length(crushCentreToPosition);
	float crushedDistance = max(fragmentDistance, crushStart * pow(fragmentDistance / crushStart, power));
	vec2 crushedFragmentPosition = crushCentre + crushedDistance * normalize(crushCentreToPosition);
	
	float fogStart = 0.95;
	float fogFactor = (fragmentDistance - fogStart * crushEnd) / ((1.0 - fogStart) * crushEnd); // TEMP: Why does fragmentDistance work but crushedDistance not work???
	float fogFactorClamped = clamp(fogFactor, 0.0, 1.0);
	
	return Texel(texture, crushedFragmentPosition / inputCanvasSize) * (1.0 - fogFactorClamped);
}

vec4 effect(vec4 colour, sampler2D texture, vec2 textureCoords, vec2 windowCoords) {
	return colour * sampleInputCanvas(texture, textureCoords * inputCanvasSize);
}
