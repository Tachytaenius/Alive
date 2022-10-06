-- WARNING: This module cannot have state expected to be universal as it is used by different threads

local bitser = require("lib.bitser")

local registry = require("registry")
local consts  = require("consts")

local serialisation = {}

-- Game instance common info

function serialisation.serialiseGameInstanceInfo(gameInstance)
	local toDump = {}
	toDump.seed = gameInstance.seed
	toDump.rngSeedLow, toDump.rngSeedHigh = gameInstance.rng:getSeed()
	toDump.time = gameInstance.time
	return bitser.dumps(toDump)
end

function serialisation.deserialiseGameInstanceInfo(serialisedGameInstanceInfo)
	local gameInstance = bitser.loads(serialisedGameInstanceInfo)
	gameInstance.rng = love.math.newRandomGenerator(gameInstance.rngSeedLow, gameInstance.rngSeedHigh)
	gameInstance.rngSeedLow, gameInstance.rngSeedHigh = nil, nil
	return gameInstance
end

-- Chunks

function serialisation.serialiseChunk(chunk)
	local toDump = {}
	toDump.randomTickTime = chunk.randomTickTime
	toDump.time = chunk.time
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
				tileToDump.topping.lumps.compressedToOne = tile.topping.lumps.compressedToOne
				tileToDump.topping.lumps.compressionLump = tile.topping.lumps.compressionLump
				tileToDump.topping.lumps.compressionLumpCount = tile.topping.lumps.compressionLumpCount
				for i, lump in ipairs(tile.topping.lumps) do
					local lumpToDump = {}
					tileToDump.topping.lumps[i] = lumpToDump
					lumpToDump.constituents = {}
					for j, entry in ipairs(lump.constituents) do
						lumpToDump.constituents[j] = {
							materialName = entry.materialName,
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
					tileToDump.superTopping.lumps.compressedToOne = tile.superTopping.lumps.compressedToOne
					tileToDump.superTopping.lumps.compressionLump = tile.superTopping.lumps.compressionLump
					tileToDump.superTopping.lumps.compressionLumpCount = tile.superTopping.lumps.compressionLumpCount
					for i, lump in ipairs(tile.superTopping.lumps) do
						local lumpToDump = {}
						tileToDump.superTopping.lumps[i] = lumpToDump
						lumpToDump.constituents = {}
						for j, entry in ipairs(lump.constituents) do
							lumpToDump.constituents[j] = {
								materialName = entry.materialName,
								amount = entry.amount
							}
						end
					end
				else -- "subLayers"
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
								materialName = entry.materialName,
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
			-- tile.chunk = chunk -- This is done later to avoid a passing a cyclical table between threads
		end
	end
	return chunk
end

return serialisation
