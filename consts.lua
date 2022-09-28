local consts = {}

consts.version = 1
consts.fixedUpdateTickLength = 1 / 24

consts.canvasSystemWidth = 480
consts.canvasSystemHeight = 270
consts.preCrushCanvasWidth = 2048
consts.preCrushCanvasHeight = 2048
consts.crushStart = 100
consts.crushEnd = consts.canvasSystemHeight - 35 -- TODO: Dynamically

consts.turningMouseMovementMultiplier = 0.01

consts.randomTickInterval = consts.fixedUpdateTickLength / 4
consts.chunkWidth = 16 -- In tiles
consts.chunkHeight = 16 -- In tiles
consts.chunkLoadingRadius = 4 * 16*16 -- In pixels, around the player
consts.chunkUnloadingRadius = 5 * 16*16 -- In pixels
consts.tileWidth = 16 -- In pixels
consts.tileHeight = 16 -- In pixels
consts.lumpConstituentsTotal = 256 -- How much the constituents counts of a lump should add up to
consts.lumpsPerLayer = 16 -- How many lumps make up a super topping wall or topping
consts.maxSubLayers = 4 -- TODO: Definitely put this in map:validate()

consts.textureNoiseSizeIrresolution = 0.25 -- Higher numbers mean fewer steps, with greater distance between
consts.minimumTextureNoiseSize = 0.2
consts.tileMeshVertexFormat = {
	{"VertexPosition", "float", 2},
	{"VertexColour", "float", 3},
	{"VertexNoiseSize", "float", 1},
	{"VertexContrast", "float", 1},
	{"VertexBrightness", "float", 1},
	{"VertexFullness", "float", 1}
}

consts.defaultFlyingRecoveryRate = 100

assert(consts.randomTickInterval > 0, "Random tick interval cannot be 0")

return consts
