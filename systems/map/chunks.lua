local registry = require("registry")
local consts = require("consts")

local chunks = {}

function chunks:removeFrom2DArray(chunk)
	self.chunks[chunk.x][chunk.y] = nil
	local hasValue = false
	for k in pairs(self.chunks[chunk.x]) do
		hasValue = true
		break
	end
	if not hasValue then
		self.chunks[chunk.x] = nil
	end
end

function chunks:addTo2DArray(chunk)
	self.chunks[chunk.x] = self.chunks[chunk.x] or {}
	assert(not self.chunks[chunk.x][chunk.y], "Chunk already exists at " .. chunk.x .. ", " .. chunk.y)
	self.chunks[chunk.x][chunk.y] = chunk
end

function chunks:generateChunk(chunkX, chunkY)
	local superWorld = self:getWorld().superWorld
	
	local chunk = {
		x = chunkX, y = chunkY,
		-- tickCursorX = 0, tickCursorY = 0 -- NOTE: For unused non-random ticks
	}
	
	-- Make the tiles
	local tiles = {}
	chunk.tiles = tiles
	for localTileX = 0, consts.chunkWidth - 1 do
		local tilesColumn = {}
		tiles[localTileX] = tilesColumn
		for localTileY = 0, consts.chunkHeight - 1 do
			local globalTileX, globalTileY = chunkX * consts.chunkWidth + localTileX, chunkY * consts.chunkHeight + localTileY
			local tile = {
				lastTickTimer = superWorld.tickTimer,
				chunk = chunk,
				localTileX = localTileX, localTileY = localTileY,
				globalTileX = globalTileX, globalTileY = globalTileY
			}
			tilesColumn[localTileY] = tile
			
			-- Generate topping
			tile.topping = {
				type = "solid",
				lumps = {}
			}
			local constituents = self:generateConstituents(globalTileX, globalTileY, self.soilMaterials)
			for _=1, consts.lumpsPerLayer do
				local lump = {}
				tile.topping.lumps[#tile.topping.lumps + 1] = lump
				lump.constituents = constituents
			end
			
			-- Generate super topping
			tile.superTopping = {
				type = "layers",
				subLayers = {}
			}
			local subLayerIndex = 1
			local grassMaterial = registry.materials.byName.grass
			local newSubLayer = {
				type = "grass",
				lump = {
					constituents = {
						{material = grassMaterial, amount = consts.lumpConstituentsTotal}
					}
				}
			}
			tile.superTopping.subLayers[subLayerIndex] = newSubLayer
			self:updateLumpDependentTickValues(tile)
			newSubLayer.grassHealth = newSubLayer.grassTargetHealth
			newSubLayer.grassAmount	= math.max(0, math.min(1, newSubLayer.grassHealth + grassMaterial.targetGrassAmountAdd))
			
			self:updateTileRendering(tile)
		end
	end
	
	return chunk
end

function chunks:loadChunk(x, y)
	-- TODO: From file
	self.loadedChunks:add(chunk)
end

function chunks:unloadChunk(chunk)
	self.loadedChunks:remove(chunk)
	-- TODO: To file
end

return chunks
