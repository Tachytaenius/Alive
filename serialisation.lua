local bitser = require("lib.bitser")

local registry = require("registry")
local consts  = require("consts")

local serialisation = {}

-- Super world common info

function serialisation.serialiseSuperWorldInfo(superWorld)
	local toDump = {}
	toDump.seed = superWorld.seed
	toDump.rngSeedLow, toDump.rngSeedHigh = superWorld.rng:getSeed()
	toDump.time = superWorld.time
	return bitser.dumps(toDump)
end

function serialisation.deserialiseSuperWorldInfo(serialisedSuperWorldInfo)
	local superWorld = bitser.loads(serialisedSuperWorldInfo)
	superWorld.rng = love.math.newRandomGenerator(superWorld.rngSeedLow, superWorld.rngSeedHigh)
	superWorld.rngSeedLow, superWorld.rngSeedHigh = nil, nil
	return superWorld
end

-- Chunks

function serialisation.serialiseChunk(chunk)
	local toDump = {}
	toDump.randomTickTime = chunk.randomTickTime
	toDump.tiles = {}
	for x = 0, consts.chunkWidth - 1 do
		toDump.tiles[x] = {}
		for y = 0, consts.chunkHeight - 1 do
			local tile = chunk.tiles[x][y]
			local tileToDump = {}
			toDump.tiles[x][y] = tileToDump
			if tile.topping then
				tileToDump.topping = {}
				tileToDump.topping.type = tile.topping.type
				tileToDump.topping.lumps = {}
				for i, lump in ipairs(tile.topping.lumps) do
					local lumpToDump = {}
					tileToDump.topping.lumps[i] = lumpToDump
					lumpToDump.constituents = {}
					for j, entry in ipairs(lump.constituents) do
						lumpToDump.constituents[j] = {
							material = entry.material.name,
							amount = entry.amount
						}
					end
				end
			end
			if tile.superTopping then
				tileToDump.superTopping = {}
				tileToDump.superTopping.type = tile.superTopping.type
				if tile.superTopping.type == "wall" then
					tileToDump.superTopping.lumps = {}
					for i, lump in ipairs(tile.superTopping.lumps) do
						local lumpToDump = {}
						tileToDump.superTopping.lumps[i] = lumpToDump
						lumpToDump.constituents = {}
						for j, entry in ipairs(lump.constituents) do
							lumpToDump.constituents[j] = {
								material = entry.material.name,
								amount = entry.amount
							}
						end
					end
				else -- "layers"
					tileToDump.superTopping.subLayers = {}
					for i, subLayer in ipairs(tile.superTopping.subLayers) do
						local subLayerToDump = {}
						tileToDump.superTopping.subLayers[i] = subLayerToDump
						subLayerToDump.type = subLayer.type
						local lumpToDump = {}
						lumpToDump.grassHealth = subLayer.lump.grassHealth
						lumpToDump.grassAmount = subLayer.lump.grassAmount
						lumpToDump.constituents = {}
						for j, entry in ipairs(subLayer.lump.constituents) do
							lumpToDump.constituents[j] = {
								material = entry.material.name,
								amount = entry.amount
							}
						end
						subLayerToDump.lump = lumpToDump
					end
				end
			end
			tileToDump.lastTimeTicked = tile.lastTimeTicked
		end
	end
	return bitser.dumps(toDump)
end

function serialisation.deserialiseChunk(serialisedChunk, x, y)
	local chunk = bitser.loads(serialisedChunk)
	chunk.x, chunk.y = x, y
	for tileX = 0, consts.chunkWidth - 1 do
		for tileY = 0, consts.chunkHeight - 1 do
			local tile = chunk.tiles[tileX][tileY]
			tile.localTileX, tile.localTileY = tileX, tileY
			tile.globalTileX, tile.globalTileY = tileX + x * consts.chunkWidth, tileY + y * consts.chunkHeight
			tile.chunk = chunk
			if tile.topping then
				for _, lump in ipairs(tile.topping.lumps) do
					for _, entry in ipairs(lump.constituents) do
						entry.material = registry.materials.byName[entry.material]
					end
				end
			end
			if tile.superTopping then
				if tile.superTopping.type == "wall" then
					for _, lump in ipairs(tile.superTopping.lumps) do
						for _, entry in ipairs(lump.constituents) do
							entry.material = registry.materials.byName[entry.material]
						end
					end
				else -- "layers"
					for _, subLayer in ipairs(tile.superTopping.subLayers) do
						for _, entry in ipairs(subLayer.lump.constituents) do
							entry.material = registry.materials.byName[entry.material]
						end
					end
				end
			end
		end
	end
	return chunk
end

return serialisation
