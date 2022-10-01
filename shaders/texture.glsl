uniform vec2 noiseTextureSize;
uniform sampler2D noiseTexture;

// TODO: Prefix all of these with fragment
varying vec2 fragmentPosition;
varying vec3 fragmentColour;
varying vec4 lightInfoColour;
varying float noiseSize;
varying float contrast;
varying float brightness;
varying float fullness; // Controls amount of pixels to discard

#ifdef VERTEX
	attribute vec3 VertexColour;
	attribute vec4 VertexLightInfoColour;
	attribute float VertexNoiseSize;
	attribute float VertexContrast;
	attribute float VertexBrightness;
	attribute float VertexFullness;
	
	vec4 position(mat4 transformProjection, vec4 vertexPosition) {
		vec4 transformedPosition = transformProjection * vertexPosition;
		
		fragmentPosition = vertexPosition.xy;
		fragmentColour = VertexColour.rgb; // Avoid gamma correct of VaryingColor
		lightInfoColour = VertexLightInfoColour;
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
		vec2 noisePos = fragmentPosition / noiseSize;
		float noise = Texel(noiseTexture, noisePos / noiseTextureSize).r;
		if (1 - noise > fullness) { // The operation applied to noise is an aesthetic choice. Would not need to be done if fullness used a separate noise field
			discard;
		}
		noise = (noise - 0.5) * 2.0 * contrast + 0.5;
		noise += brightness;
		love_Canvases[0] = vec4(fragmentColour * noise, 1.0); // Albedo
		love_Canvases[1] = lightInfoColour; // Light info. Rely on alpha to not change light info canvas if not supposed to
	}
#endif
