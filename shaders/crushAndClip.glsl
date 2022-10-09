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
uniform float fogFadeLength;
uniform sampler2D lightingCanvas;
uniform sampler2D lightFilterCanvas;

float distanceToLine(vec2 lineStart, vec2 lineEnd, vec2 point) {
	vec2 v1 = lineEnd - lineStart;
	vec2 v2 = lineStart - point;
	vec2 v3 = vec2(v1.y, -v1.x);
	return abs(dot(v2, normalize(v3)));
}

float calculateFogFactor(float dist, float maxDist, float fogFadeLength) { // More fog the further you are
	if (fogFadeLength == 0.0) { // Avoid dividing by zero
		return dist < maxDist ? 0.0 : 1.0;
	}
	return clamp((dist - maxDist + fogFadeLength) / fogFadeLength, 0.0, 1.0);
}

float calculateFogFactor2(float dist, float fogFadeLength) { // More fog the closer you are
	if (fogFadeLength == 0.0) { // Avoid dividing by zero
		return 1.0; // Immediate fog
	}
	return clamp(1 - dist / fogFadeLength, 0.0, 1.0);
}

vec2 directionFromAngle(float angle) {
	return vec2(cos(angle), sin(angle));
}

vec3 getInputCanvasSamplePosAndFogFactor(vec2 fragmentPosition) {
	// Returns pos in xy and fog factor in z
	
	vec2 crushCentreToPosition = fragmentPosition - crushCentre;
	float fragmentDistance = length(crushCentreToPosition);
	float crushedDistance = max(fragmentDistance, crushStart * pow(fragmentDistance / crushStart, power));
	vec2 crushedFragmentPosition = crushCentre + crushedDistance * normalize(crushCentreToPosition);
	
	float sensingCircleFogFactor = calculateFogFactor(fragmentDistance, sensingCircleRadius, fogFadeLength);
	float fullViewDistanceFogFactor = calculateFogFactor(fragmentDistance, crushEnd, fogFadeLength); // TEMP: Why does fragmentDistance work but crushedDistance not work???
	float angle = atan(crushCentreToPosition.x, -crushCentreToPosition.y); // x and y are swapped around, normally the inputs are y, x. The input to the x parameter is also negated. This is to rotate the angle for easier maths (HACK, I guess?)
	float distanceToFovSides = min(
		distanceToLine(crushCentre, crushCentre + crushEnd * directionFromAngle(fov / 2.0 + tau / 4.0), fragmentPosition),
		distanceToLine(crushCentre, crushCentre + crushEnd * directionFromAngle(-(fov / 2.0 + tau / 4.-0)), fragmentPosition)
	);
	float fovFogFactor = abs(angle) < fov / 2.0 ? calculateFogFactor2(distanceToFovSides, fogFadeLength) : 1.0;
	float fogFactor = min(sensingCircleFogFactor, max(fullViewDistanceFogFactor, fovFogFactor));
	
	return vec3(crushedFragmentPosition / inputCanvasSize, fogFactor);
}

void effect() {
	vec3 sampleInfo = getInputCanvasSamplePosAndFogFactor(VaryingTexCoord.xy * inputCanvasSize);
	love_Canvases[0] = Texel(lightingCanvas, sampleInfo.xy) * (1.0 - sampleInfo.z);
	love_Canvases[1] = Texel(lightFilterCanvas, sampleInfo.xy);
}
