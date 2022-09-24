local consts = {}

consts.preCrushCanvasWidth = 1024
consts.preCrushCanvasHeight = 1024

consts.tileWidth = 16
consts.tileHeight = 16
consts.chunkConstituentsTotal = 256 -- How much the constituents counts of a chunk should add up to
consts.chunksPerLayer = 16 -- How many chunks make up a super topping wall or topping

consts.textureNoiseSizeIrresolution = 0.25 -- Higher numbers mean fewer steps, with greater distance between
consts.minimumTextureNoiseSize = 0.2

consts.defaultFlyingRecoveryRate = 100

return consts
