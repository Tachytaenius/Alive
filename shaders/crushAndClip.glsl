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

float calculateFogFactor(float dist, float maxDist, float fogLength) {
	return clamp((dist - maxDist + fogLength) / fogLength, 0.0, 1.0);
}

vec4 sampleInputCanvas(sampler2D texture, vec2 fragmentPosition) {
	vec2 crushCentreToPosition = fragmentPosition - crushCentre;
	float fragmentDistance = length(crushCentreToPosition);
	float crushedDistance = max(fragmentDistance, crushStart * pow(fragmentDistance / crushStart, power));
	vec2 crushedFragmentPosition = crushCentre + crushedDistance * normalize(crushCentreToPosition);
	
	float fogLength = 10.0;
	float sensingCircleFogFactor = calculateFogFactor(fragmentDistance, sensingCircleRadius, fogLength);
	float fullViewDistanceFogFactor = calculateFogFactor(fragmentDistance, crushEnd, fogLength); // TEMP: Why does fragmentDistance work but crushedDistance not work???
	float angle = atan(crushCentreToPosition.x, -crushCentreToPosition.y); // x and y are swapped around, normally the inputs are y, x. The input to the x parameter is also negated. This is to rotate the angle for easier maths (HACK, I guess?)
	float angleFogLength = 0.1;
	float fovFogFactor = calculateFogFactor(abs(angle), fov / 2.0, angleFogLength);
	float fogFactor = min(sensingCircleFogFactor, max(fullViewDistanceFogFactor, fovFogFactor));
	
	return Texel(texture, crushedFragmentPosition / inputCanvasSize) * (1.0 - fogFactor);
}

vec4 effect(vec4 colour, sampler2D texture, vec2 textureCoords, vec2 windowCoords) {
	return colour * sampleInputCanvas(texture, textureCoords * inputCanvasSize);
}
