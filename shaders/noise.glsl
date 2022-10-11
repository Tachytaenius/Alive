uniform vec2 noiseTextureSize;
uniform sampler2D noiseTexture;
uniform float fullnessNoiseSize;
uniform float fullnessNoiseOffset;

varying vec2 fragmentPosition;
varying vec4 fragmentColour;
varying vec4 fragmentLightFilterColour;
varying float fragmentNoiseSize;
varying float fragmentContrast;
varying float fragmentBrightness;
varying float fragmentNoiseFullness; // Controls amount of pixels to discard

#ifdef VERTEX
	attribute vec4 VertexLightFilterColour;
	attribute float VertexNoiseSize;
	attribute float VertexContrast;
	attribute float VertexBrightness;
	attribute float VertexFullness;

	vec4 position(mat4 transformProjection, vec4 vertexPosition) {
		vec4 transformedPosition = transformProjection * vertexPosition;

		fragmentPosition = vertexPosition.xy;
		fragmentColour = gammaCorrectColor(VertexColor);
		fragmentLightFilterColour = gammaCorrectColor(VertexLightFilterColour);
		fragmentNoiseSize = VertexNoiseSize;
		fragmentContrast = VertexContrast;
		fragmentBrightness = VertexBrightness;
		fragmentNoiseFullness = VertexFullness;

		return transformedPosition;
	}
#endif

#ifdef PIXEL
	// love.graphics.setColor has no effect here
	void effect() {
		vec2 fullnessNoisePos = fragmentPosition / fullnessNoiseSize + fullnessNoiseOffset;
		float fullnessNoise = Texel(noiseTexture, fullnessNoisePos / noiseTextureSize).r;
		if (fullnessNoise > fragmentNoiseFullness) {
			discard;
		}

		vec2 noisePos = fragmentPosition / fragmentNoiseSize;
		float noise = Texel(noiseTexture, noisePos / noiseTextureSize).r;
		noise = noise * 2.0 - 1.0; // To [-1, 1]
		noise *= fragmentContrast;
		noise += fragmentBrightness * 2.0 - 1.0;
		noise = noise / 2.0 + 0.5; // Back to [0, 1]

		love_Canvases[0] = vec4(fragmentColour.rgb * noise, fragmentColour.a); // Albedo
		love_Canvases[1] = fragmentLightFilterColour; // Light filter. Rely on alpha to not change light filter canvas if not supposed to
	}
#endif
