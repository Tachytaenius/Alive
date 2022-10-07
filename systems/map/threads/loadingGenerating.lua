require("love.math")

local consts = require("consts")
local serialisation = require("util").saveFiles.serialisation
local tiles = require("systems.map.tiles")

local registry -- = require("registry")
local soilMaterials
local gameInstanceSeed

local subWorldId = ...

local quitChannel = love.thread.getChannel(consts.quitChannelName)
local infoChannelName = love.thread.getChannel(consts.chunkInfoChannelName .. subWorldId)
local requestChannel = love.thread.getChannel(consts.chunkLoadingRequestChannelName .. subWorldId)
local resultChannel = love.thread.getChannel(consts.chunkLoadingResultChannelName .. subWorldId)

local function generateConstituents(x, y, materialsSet)
	-- All constituents must add up to const.lumpConstituentsTotal
	local constituents = {}
	
	-- Get base weights
	local total1 = 0
	
	for i, materialsSetEntry in pairs(materialsSet) do
		local material = registry.materials.byName[materialsSetEntry.materialName]
		
		local noise = love.math.noise(
			x / (materialsSetEntry.noiseWidth or 1),
			y / (materialsSetEntry.noiseHeight or 1),
			material.id + gameInstanceSeed
		)
		
		local amount = noise * materialsSetEntry.abundanceMultiply + (materialsSetEntry.abundanceAdd or 0)
		constituents[i] = {materialName = materialsSetEntry.materialName, amount = amount}
		total1 = total1 + amount
	end
	
	-- Get proper amounts
	local total2 = 0
	for i, entry in ipairs(constituents) do
		entry.amount = math.floor(consts.lumpConstituentsTotal * entry.amount / total1)
		total2 = total2 + entry.amount
	end
	
	-- Spread remainder (this could be done differently)
	local i = 1
	for _ = 1, consts.lumpConstituentsTotal - total2 do
		constituents[i].amount = constituents[i].amount + 1
		i = (i - 1 + 1) % #constituents + 1
	end
	
	-- Debug test
	-- local total3 = 0
	-- for i, entry in ipairs(constituents) do
	-- 	total3 = total3 + entry.amount
	-- end
	-- assert(total3 == consts.lumpConstituentsTotal)
	
	return constituents
end

local function generateTile(chunk, localTileX, localTileY)
	local globalTileX, globalTileY = chunk.x * consts.chunkWidth + localTileX, chunk.y * consts.chunkHeight + localTileY
	local tile = {
		lastTimeTicked = chunk.time,
		-- chunk = chunk, -- cycles aren't supported
		localTileX = localTileX, localTileY = localTileY,
		globalTileX = globalTileX, globalTileY = globalTileY
	}
	chunk.tiles[localTileX][localTileY] = tile
	
	-- Generate topping
	tile.topping = {
		type = "solid",
		lumps = {}
	}
	local constituents = generateConstituents(globalTileX, globalTileY, soilMaterials)
	tile.topping.lumps.compressedToOne = true
	tile.topping.lumps.compressionLump = {
		constituents = constituents
	}
	tile.topping.lumps.compressionLumpCount = consts.lumpsPerLayer
	
	-- Generate super topping
	if love.math.random() < 0.01 then -- TEMP: We can't actually use the game instance RNG in a thread (undefined order) nor love's own one anywhere in fixed update (intended to be used elsewhere like in graphics) for determinism reasons
		tile.superTopping = {
			type = "wall",
			lumps = {}
		}
		tile.superTopping.lumps.compressedToOne = true
		tile.superTopping.lumps.compressionLump = {
			constituents = {
				{materialName = "stone", amount = consts.lumpConstituentsTotal}
			}
		}
		tile.superTopping.lumps.compressionLumpCount = consts.lumpsPerLayer
		tiles:updateLumpDependentTickValues(tile, registry)
	else
		tile.superTopping = {
			type = "subLayers",
			subLayers = {}
		}
		local subLayerIndex = 1
		local newSubLayer = {
			type = "grass",
			lump = {
				constituents = {
					{materialName = "grass", amount = consts.lumpConstituentsTotal}
				}
			}
		}
		tile.superTopping.subLayers[subLayerIndex] = newSubLayer
		tiles:updateLumpDependentTickValues(tile, registry)
		newSubLayer.lump.grassHealth = newSubLayer.grassTargetHealth
		local healthAdd = newSubLayer.lump.grassHealth > 0 and newSubLayer.mixedGrassTargetAmountAdd or 0
		newSubLayer.lump.grassAmount = math.max(0, math.min(1, newSubLayer.lump.grassHealth + healthAdd))
	end
	
	return tile
end

local function generateChunk(chunkX, chunkY)
	local chunk = {
		x = chunkX, y = chunkY,
		time = 0,
		randomTickTime = 0
	}
	
	-- Make the tiles
	local tiles = {}
	chunk.tiles = tiles
	for localTileX = 0, consts.chunkWidth - 1 do
		tiles[localTileX] = {}
		for localTileY = 0, consts.chunkHeight - 1 do
			generateTile(chunk, localTileX, localTileY)
		end
	end
	
	return chunk
end

while quitChannel:peek() ~= "quit" do
	local newInfo = infoChannelName:pop()
	if newInfo then
		registry = newInfo.registry or registry
		soilMaterials = newInfo.soilMaterials or soilMaterials
		gameInstanceSeed = newInfo.gameInstanceSeed or gameInstanceSeed
	end
	
	local chunkRequestCoords = requestChannel:pop()
	if chunkRequestCoords then
		assert(registry, "Registry not passed to thread")
		assert(registry.loaded, "Registry passed to thread not loaded")
		assert(soilMaterials, "Soil materials not passed to thread")
		
		-- Load or generate chunk
		local x, y = chunkRequestCoords.x, chunkRequestCoords.y
		
		local path = "chunks/" .. x .. "," .. y .. ".bin"
		local info = love.filesystem.getInfo(path)
		if not info then
			local chunk = generateChunk(x, y)
			resultChannel:push(chunk)
		elseif info.type == "directory" then
			error(path .. " is a directory")
		else
			local serialisedData, errorMessage = love.filesystem.read(path)
			assert(serialisedData, "Could not read file for chunk at " .. x .. ", " .. y .. ": " .. errorMessage)
			local chunk = serialisation.deserialiseChunk(serialisedData, x, y)
			for x = 0, consts.chunkWidth - 1 do
				for y = 0, consts.chunkHeight - 1 do
					local tile = chunk.tiles[x][y]
					tiles:updateLumpDependentTickValues(tile, registry)
				end
			end
			
			resultChannel:push(chunk)
		end
	end
end
