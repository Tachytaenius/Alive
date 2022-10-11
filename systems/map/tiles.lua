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

local function updateGrassMixedMaterialParameters(tile, threadRegistry)
	-- WARNING: Used in a different copy to the map system's copy of the tiles table by one or more extra threads!
	-- Excludes rendering parameters (though grassNoiseFullness1 is included), that is done by the updateTileRendering function

	local registry = threadRegistry or registry
	if not tile.superTopping then
		return
	end
	if tile.superTopping.type ~= "subLayers" then
		return
	end

	for i = 1, #tile.superTopping.subLayers do
		local subLayer = tile.superTopping.subLayers[i]

		local weightTotal = 0
		local grassHealthIncreaseRate = 0
		local grassHealthDecreaseRate = 0
		local grassGrowthRate = 0
		local grassDecayRate = 0
		local grassTargetAmountAdd = 0
		local grassNoiseFullness1 = 0
		local grassTargetHealthZero = 0

		for _, entry in ipairs(subLayer.lump.constituents) do
			local material = registry.materials.byName[entry.materialName]

			local weight = entry.amount
			weightTotal = weightTotal + weight
			grassHealthIncreaseRate = grassHealthIncreaseRate + material.grassHealthIncreaseRate * weight
			grassHealthDecreaseRate = grassHealthDecreaseRate + material.grassHealthDecreaseRate * weight
			grassGrowthRate = grassGrowthRate + material.grassGrowthRate * weight
			grassDecayRate = grassDecayRate + material.grassDecayRate * weight
			grassTargetAmountAdd = grassTargetAmountAdd + material.grassTargetAmountAdd * weight
			grassNoiseFullness1 = grassNoiseFullness1 + material.grassNoiseFullness1 * weight
			grassTargetHealthZero = grassTargetHealthZero + material.grassTargetHealthZero * weight
		end

		subLayer.mixedGrassHealthIncreaseRate = grassHealthIncreaseRate / weightTotal
		subLayer.mixedGrassHealthDecreaseRate = grassHealthDecreaseRate / weightTotal
		subLayer.mixedGrassGrowthRate = grassGrowthRate / weightTotal
		subLayer.mixedGrassDecayRate = grassDecayRate / weightTotal
		subLayer.mixedGrassTargetAmountAdd = grassTargetAmountAdd / weightTotal
		subLayer.mixedGrassNoiseFullness1 = grassNoiseFullness1 / weightTotal
		subLayer.mixedGrassTargetHealthZero = grassTargetHealthZero / weightTotal
	end
end

local function getGrassTargetHealth(tile, subLayerIndex, threadRegistry)
	-- WARNING: Used in a different copy to the map system's copy of the tiles table by one or more extra threads!
	local registry = threadRegistry or registry
	local subLayer = tile.superTopping.subLayers[subLayerIndex]
	local x, y = tile.globalTileX, tile.globalTileY
	local loamAmount, waterAmount = 0, 0
	if subLayerIndex == 1 and tile.topping then
		local lumps = tile.topping.lumps
		local topLump = lumps.compressedToOne and lumps.compressionLump or lumps[#lumps]
		for _, entry in ipairs(topLump.constituents) do
			if entry.materialName == "loam" then
				loamAmount = entry.amount
			elseif entry.materialName == "water" then
				waterAmount = entry.amount
			end
		end
	elseif subLayerIndex ~= 1 then
		error("Grass can't exist on any subLayer except the bottom one")
	end
	local loamFractionTarget = 0.3
	local waterFractionTarget = 0.3
	local loamHealthMultiplier = math.min(1, (loamAmount / consts.lumpConstituentsTotal) / loamFractionTarget)
	local waterHealthMultiplier = math.min(1, (waterAmount / consts.lumpConstituentsTotal) / waterFractionTarget)
	local preZeroTargetHealth = loamHealthMultiplier * waterHealthMultiplier
	if preZeroTargetHealth <= (subLayer.mixedGrassTargetHealthZero or 0) then
		return 0
	else
		return preZeroTargetHealth
	end
end

local function updateGrassTargetHealths(tile, threadRegistry)
	-- WARNING: Used in a different copy to the map system's copy of the tiles table by one or more extra threads!
	if not tile.superTopping then
		return
	end
	if tile.superTopping.type ~= "subLayers" then
		return
	end
	for i = 1, #tile.superTopping.subLayers do
		tile.superTopping.subLayers[i].grassTargetHealth = getGrassTargetHealth(tile, i, threadRegistry)
	end
end

function tiles:updateLumpDependentTickValues(tile, threadRegistry)
	-- WARNING: Used in a different copy to the map system's copy of the tiles table by one or more extra threads!
	-- Only values relevant to fixed update, and only values dependent on the tile's lumps
	updateGrassMixedMaterialParameters(tile, threadRegistry)
	updateGrassTargetHealths(tile, threadRegistry)
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
		if tile.superTopping.type == "subLayers" then
			-- Iterate over the sub-layers
			local i = 1
			while i <= #tile.superTopping.subLayers do
				local subLayer = tile.superTopping.subLayers[i]
				local toDelete = false
				if subLayer.type == "grass" then
					-- Delete grass of amount 0
					if subLayer.lump.grassAmount == 0 then
						toDelete = true
						changedRendering = true
					else
						-- Update health
						local prevHealth = subLayer.lump.grassHealth
						local targetHealth = subLayer.grassTargetHealth
						if targetHealth > subLayer.lump.grassHealth then -- Add to health using grassHealthIncreaseRate
							subLayer.lump.grassHealth = math.min(targetHealth, subLayer.lump.grassHealth + subLayer.mixedGrassHealthIncreaseRate * effectiveDt)
							changedRendering = true
						elseif targetHealth < subLayer.lump.grassHealth then -- Subtract from health using grassHealthDecreaseRate
							subLayer.lump.grassHealth = math.min(targetHealth, subLayer.lump.grassHealth - subLayer.mixedGrassHealthDecreaseRate * effectiveDt)
							changedRendering = true
						end

						-- Update amount
						-- Speed of approach should be multiplied with 1 - health downwards and with health upwards.
						-- Check docs/materials.md.
						local healthAdd = subLayer.lump.grassHealth > 0 and subLayer.mixedGrassTargetAmountAdd or 0
						local targetAmount = math.max(0, math.min(1, subLayer.lump.grassHealth + healthAdd))
						if targetAmount > subLayer.lump.grassAmount then -- Add to amount using grassHealth and grassGrowthRate
							subLayer.lump.grassAmount = math.min(targetAmount, subLayer.lump.grassAmount + subLayer.mixedGrassGrowthRate * subLayer.lump.grassHealth * effectiveDt)
							changedRendering = true
						elseif targetAmount < subLayer.lump.grassAmount then -- Subtract from amount using 1 - grassHealth and grassDecayRate
							subLayer.lump.grassAmount = math.max(targetAmount, subLayer.lump.grassAmount - subLayer.mixedGrassDecayRate * (1 - subLayer.lump.grassHealth) * effectiveDt)
							changedRendering = true
						end
					end
				end
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
	return changedRendering
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
