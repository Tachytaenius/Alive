require("love.math")

local consts = require("consts")
local serialisation = require("serialisation")
local tiles = require("systems.map.tiles")

local registry -- = require("registry")
local soilMaterials
local superWorldSeed

-- TODO: Minor refactor so that only sub-world id is passed and consts is used

local quitChannelName, infoChannelName, requestChannelName, resultChannelName = ...

local quitChannel = love.thread.getChannel(quitChannelName)
local infoChannelName = love.thread.getChannel(infoChannelName)
local requestChannel = love.thread.getChannel(requestChannelName)
local resultChannel = love.thread.getChannel(resultChannelName)

local function generateConstituents(x, y, materialsSet)
	-- All constituents must add up to const.lumpConstituentsTotal
	local constituents = {}
	
	-- Get base weights
	local total1 = 0
	
	for i, materialsSetEntry in pairs(materialsSet) do
		local material = registry.materials.byName[materialsSetEntry.materialName]
		
		local noise = love.math.noise(
			x / (material.noiseWidth or 1),
			y / (material.noiseHeight or 1),
			material.id + superWorldSeed
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
	tile.superTopping = {
		type = "layers",
		subLayers = {}
	}
	local subLayerIndex = 1
	local grassMaterialName = "grass"
	local grassMaterial = registry.materials.byName[grassMaterialName]
	local newSubLayer = {
		type = "grass",
		lump = {
			constituents = {
				{materialName = grassMaterialName, amount = consts.lumpConstituentsTotal}
			}
		}
	}
	tile.superTopping.subLayers[subLayerIndex] = newSubLayer
	tiles:updateLumpDependentTickValues(tile)
	newSubLayer.lump.grassHealth = newSubLayer.grassTargetHealth
	newSubLayer.lump.grassAmount = math.max(0, math.min(1, newSubLayer.lump.grassHealth + grassMaterial.grassTargetAmountAdd))
	
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
		superWorldSeed = newInfo.superWorldSeed or superWorldSeed
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
					tiles:updateLumpDependentTickValues(tile)
				end
			end
			
			resultChannel:push(chunk)
		end
	end
end