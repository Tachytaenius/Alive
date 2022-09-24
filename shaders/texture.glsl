uniform vec2 noiseTextureSize;
uniform sampler2D noiseTexture;
uniform vec2 tileSize;

uniform bool useNoise;
uniform vec2 tilePosition;

uniform float noiseSize;
uniform float contrast;
uniform float brightness;
uniform float fullness; // Controls amount of pixels to discard

vec4 effect(vec4 colour, sampler2D texture, vec2 textureCoords, vec2 windowCoords) {
	vec4 fragmentColour = Texel(texture, textureCoords);
	if (useNoise) {
		vec2 noisePos = (textureCoords * tileSize + tilePosition) / noiseSize;
		float noise = Texel(noiseTexture, noisePos / noiseTextureSize).r;
		if (1 - noise > fullness) { // The operation applied to noise is an aesthetic choice. Would not need to be done if fullness used a separate noise field
			discard;
		}
		noise = (noise + 1) / 2.0;
		noise = (noise - 0.5) * 2.0 * contrast + 0.5;
		noise += brightness;
		return vec4(colour.rgb * noise, 1.0);
	}
	return colour * fragmentColour;
}
