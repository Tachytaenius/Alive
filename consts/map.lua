local map = {}

map.chunkWidth = 16 -- In tiles
map.chunkHeight = 16 -- In tiles
map.chunkProcessingRadius = 4 * 16*16 -- In pixels, around the player
map.chunkForceLoadingRadius = 6 * 16*16 -- In pixels
map.chunkLoadingRadius = 7 * 16*16 -- In pixels
map.chunkUnloadingRadius = 8 * 16*16 -- In pixels
map.tileWidth = 16 -- In pixels
map.tileHeight = 16 -- In pixels
map.lumpConstituentsTotal = 256 -- How much the constituents counts of a lump should add up to
map.lumpsPerLayer = 16 -- How many lumps make up a super topping wall or topping
map.maxSubLayers = 4 -- TODO: Definitely put this in map:validate()

return map
