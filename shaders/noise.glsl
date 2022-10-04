uniform vec2 noiseTextureSize;
uniform sampler2D noiseTexture;
uniform float fullnessNoiseSize;
uniform float fullnessNoiseOffset;

// TODO: Prefix all of these with fragment
varying vec2 fragmentPosition;
varying vec3 fragmentColour;
varying vec4 lightFilterColour;
varying float noiseSize;
varying float contrast;
varying float brightness;
varying float fullness; // Controls amount of pixels to discard

#ifdef VERTEX
	attribute vec4 VertexLightFilterColour;
	attribute float VertexNoiseSize;
	attribute float VertexContrast;
	attribute float VertexBrightness;
	attribute float VertexFullness;
	
	vec4 position(mat4 transformProjection, vec4 vertexPosition) {
		vec4 transformedPosition = transformProjection * vertexPosition;
		
		fragmentPosition = vertexPosition.xy;
		fragmentColour = gammaCorrectColor(VertexColor.rgb);
		lightFilterColour = gammaCorrectColor(VertexLightFilterColour);
		noiseSize = VertexNoiseSize;
		contrast = VertexContrast;
		brightness = VertexBrightness;
		fullness = VertexFullness;
		
		return transformedPosition;
	}
#endif

#ifdef PIXEL
	// love.graphics.setColor has no effect here
	void effect() {
		vec2 fullnessNoisePos = fragmentPosition / fullnessNoiseSize + fullnessNoiseOffset;
		float fullnessNoise = Texel(noiseTexture, fullnessNoisePos / noiseTextureSize).r;
		if (fullnessNoise > fullness) {
			discard;
		}
		
		vec2 noisePos = fragmentPosition / noiseSize;
		float noise = Texel(noiseTexture, noisePos / noiseTextureSize).r;
		noise = noise * 2.0 - 1.0; // To [-1, 1]
		noise *= contrast;
		noise += brightness * 2.0 - 1.0;
		noise = noise / 2.0 + 0.5; // Back to [0, 1]
		
		love_Canvases[0] = vec4(fragmentColour * noise, 1.0); // Albedo
		love_Canvases[1] = lightFilterColour; // Light filter. Rely on alpha to not change light filter canvas if not supposed to
	}
#endif
