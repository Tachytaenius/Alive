local graphics = {}

graphics.canvasSystemWidth = 480
graphics.canvasSystemHeight = 270
graphics.preCrushCanvasWidth = 2048
graphics.preCrushCanvasHeight = 2048
graphics.crushEnd = graphics.canvasSystemHeight - 35
graphics.lightInfluenceTextureSize = 256
graphics.linearFilterLightInfoCanvas = false
graphics.shadowTextureRevealDepth = 12
graphics.shadowForceTextureNonRevealMinDepth = 4
graphics.textureNoiseSizeIrresolution = 0.25 -- Higher numbers mean fewer steps, with greater distance between
graphics.minimumTextureNoiseSize = 0.2
graphics.tileMeshVertexFormat = {
	{"VertexPosition", "float", 2},
	{"VertexColor", "float", 3},
	{"VertexLightInfoColour", "float", 4},
	{"VertexNoiseSize", "float", 1},
	{"VertexContrast", "float", 1},
	{"VertexBrightness", "float", 1},
	{"VertexFullness", "float", 1}
}

return graphics
