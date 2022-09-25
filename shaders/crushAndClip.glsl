const float pi = 3.1415926538;
const float tau = pi * 2.0;

uniform vec2 inputCanvasSize;
uniform vec2 outputCanvasSize;
uniform vec2 crushCentre;
uniform float crushStart;
uniform float crushEnd;
uniform float sensingCircleRadius;
uniform float fov;
uniform float power;

vec4 sampleInputCanvas(sampler2D texture, vec2 fragmentPosition) {
	vec2 crushCentreToPosition = fragmentPosition - crushCentre;
	float fragmentDistance = length(crushCentreToPosition);
	float crushedDistance = max(fragmentDistance, crushStart * pow(fragmentDistance / crushStart, power));
	vec2 crushedFragmentPosition = crushCentre + crushedDistance * normalize(crushCentreToPosition);
	
	float fogLength = 10.0; // TODO: Constant value on Lua side
	float sensingCircleFogFactor = (fragmentDistance - sensingCircleRadius + fogLength) / fogLength;
	float fullViewDistanceFogFactor = (fragmentDistance - crushEnd + fogLength) / fogLength; // TEMP: Why does fragmentDistance work but crushedDistance not work???
	float angle = atan(crushCentreToPosition.x, -crushCentreToPosition.y); // x and y are swapped around, normally the inputs are y, x. The input to the x parameter is also negated. This is to rotate the angle for easier maths (HACK, I guess?)
	float angleFogLength = 0.1;
	float fovFogFactor = (abs(angle) - fov / 2.0 + angleFogLength) / angleFogLength;
	float fogFactorClamped = clamp(min(sensingCircleFogFactor, max(fullViewDistanceFogFactor, fovFogFactor)), 0.0, 1.0);
	
	return Texel(texture, crushedFragmentPosition / inputCanvasSize) * (1.0 - fogFactorClamped);
}

vec4 effect(vec4 colour, sampler2D texture, vec2 textureCoords, vec2 windowCoords) {
	return colour * sampleInputCanvas(texture, textureCoords * inputCanvasSize);
}
