-- WARNING: This table is used in one or more extra threads!

local registry = require("registry")
local consts = require("consts")

local tiles = {}

function tiles:getTile(x, y)
	local chunkX, chunkY = math.floor(x / consts.chunkWidth), math.floor(y / consts.chunkHeight)
	local localX, localY = x % consts.chunkWidth, y % consts.chunkHeight
	if self.loadedChunksGrid[chunkX] and self.loadedChunksGrid[chunkX][chunkY] then
		return self.loadedChunksGrid[chunkX][chunkY].tiles[localX][localY]
	end
end

local function getGrassTargetHealth(tile, subLayerIndex)
	-- WARNING: Used in a different copy to the map system's copy of the tiles table by one or more extra threads!
	local x, y = tile.globalTileX, tile.globalTileY
	-- TODO: not hardcoded (grass loam requirement, grass water requirement...)
	local loamAmount, waterAmount = 0, 0
	if subLayerIndex == 1 and tile.topping then
		local lumps = tile.topping.lumps
		assert(lumps.compressedToOne and lumps.compressionLumpCount == consts.lumpsPerLayer or #lumps == consts.lumpsPerLayer, "There must be " .. consts.lumpsPerLayer .. " lumps for grass to exist on a tile")
		local topLump = lumps.compressedToOne and lumps.compressionLump or lumps[consts.lumpsPerLayer]
		for _, entry in ipairs(topLump.constituents) do
			if entry.materialName == "loam" then
				loamAmount = entry.amount
			elseif entry.materialName == "water" then
				waterAmount = entry.amount
			end
		end
	else
		-- NOTE: Could have even more complex code where grass passes through grates and the like
		for _, entry in ipairs(tile.superTopping.subLayers[subLayerIndex - 1]) do
			if entry.materialName == "loam" then
				loamAmount = entry.amount
			elseif entry.materialName == "water" then
				waterAmount = entry.amount
			end
		end
	end
	local loamFractionTarget = 0.3
	local waterFractionTarget = 0.3
	local loamHealthMultiplier = math.min(1, (loamAmount / consts.lumpConstituentsTotal) / loamFractionTarget)
	local waterHealthMultiplier = math.min(1, (waterAmount / consts.lumpConstituentsTotal) / waterFractionTarget)
	return loamHealthMultiplier * waterHealthMultiplier
end

local function updateGrassTargetHealths(tile)
	-- WARNING: Used in a different copy to the map system's copy of the tiles table by one or more extra threads!
	if not tile.superTopping then
		return
	end
	if not tile.superTopping.type == "layers" then
		return
	end
	for i = 1, #tile.superTopping.subLayers do
		tile.superTopping.subLayers[i].grassTargetHealth = getGrassTargetHealth(tile, i)
	end
end

function tiles:updateLumpDependentTickValues(tile)
	-- WARNING: Used in a different copy to the map system's copy of the tiles table by one or more extra threads!
	-- Only values relevant to fixed update, and only values dependent on the tile's lumps
	updateGrassTargetHealths(tile)
end

function tiles:tickTile(tile, dt)
	local changedRendering
	local currentTime = tile.chunk.time
	local effectiveDt = currentTime - tile.lastTimeTicked
	if effectiveDt == 0 then
		tile.lastTimeTicked = currentTime -- This is also at the end of the function
		return
	end
	-- Update grass
	if tile.superTopping then
		if tile.superTopping.type == "layers" then
			-- Iterate over the layers
			local i = 1
			while i <= #tile.superTopping.subLayers do
				local subLayer = tile.superTopping.subLayers[i]
				local toDelete = false
				if subLayer.type == "grass" then
					-- Delete grass of amount 0
					if subLayer.lump.grassAmount == 0 then
						toDelete = true
					else
						local grassMaterial = registry.materials.byName[subLayer.lump.constituents[1].materialName]
						
						-- Update health
						local prevHealth = subLayer.lump.grassHealth
						local targetHealth = subLayer.grassTargetHealth
						if targetHealth > subLayer.lump.grassHealth then -- Add to health using grassHealthIncreaseRate
							subLayer.lump.grassHealth = math.min(targetHealth, subLayer.lump.grassHealth + grassMaterial.grassHealthIncreaseRate * effectiveDt)
							changedRendering = true
						elseif targetHealth < subLayer.lump.grassHealth then -- Subtract from health using grassHealthDecreaseRate
							subLayer.lump.grassHealth = math.min(targetHealth, subLayer.lump.grassHealth - grassMaterial.grassHealthDecreaseRate * effectiveDt)
							changedRendering = true
						end
						
						-- Update amount
						-- TODO: Grass amount of grass with health x should approach x.
						-- Speed of approach should be multiplied with 1 - health downwards and with health upwards.
						-- Check docs/materials.md.
						local targetAmount = math.max(0, math.min(1, subLayer.lump.grassHealth + grassMaterial.grassTargetAmountAdd))
						if targetAmount > subLayer.lump.grassAmount then -- Add to amount using grassHealth and grassGrowthRate
							subLayer.lump.grassAmount = math.min(targetAmount, subLayer.lump.grassAmount + grassMaterial.grassGrowthRate * subLayer.lump.grassHealth * effectiveDt)
							changedRendering = true
						elseif targetAmount < subLayer.lump.grassAmount then -- Subtract from amount using 1 - grassHealth and grassDecayRate
							subLayer.lump.grassAmount = math.max(targetAmount, subLayer.lump.grassAmount - grassMaterial.grassDecayRate * (1 - subLayer.lump.grassHealth) * effectiveDt)
							changedRendering = true
						end
					end
				end
				-- TODO: Verify this all works as intended
				if toDelete then
					table.remove(tile.superTopping.subLayers, i)
				else
					i = i + 1
				end
			end
		end
	end
	if changedRendering then
		self:updateTileRendering(tile)
	end
	tile.lastTimeTicked = currentTime
end

function tiles:decompressLumps(lumps)
	assert(lumps.compressedToOne, "Can't decompress uncompressed lumps table")
	lumps[1] = lumps.compressionLump
	for i = 2, lumps.compressionLumpCount do
		lumps[i] = {}
		for k, v in pairs(lumps.compressionLump) do
			lumps[i][k] = v
		end
	end
	lumps.compressedToOne = nil
	lumps.compressionLump = nil
	lumps.compressionLumpCount = nil
end

return tiles
