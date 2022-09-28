local consts = require("consts")

local tiles = {}

function tiles:getTile(x, y)
	local chunkX, chunkY = math.floor(x / consts.chunkWidth), math.floor(y / consts.chunkHeight)
	local localX, localY = x % consts.chunkWidth, y % consts.chunkHeight
	if self.chunks[chunkX] and self.chunks[chunkX][chunkY] then
		return self.chunks[chunkX][chunkY].tiles[localX][localY]
	end
end

function tiles:generateConstituents(x, y, materialsSet)
	-- All constituents must add up to const.lumpConstituentsTotal
	local constituents = {}
	
	-- Get base weights
	local total1 = 0
	local superWorldSeed = self:getWorld().superWorld.seed
	for i, materialsSetEntry in pairs(materialsSet) do
		local noise = love.math.noise(
			x / (materialsSetEntry.noiseWidth or 1),
			y / (materialsSetEntry.noiseHeight or 1),
			materialsSetEntry.material.id + superWorldSeed
		)
		local amount = noise * materialsSetEntry.abundanceMultiply + (materialsSetEntry.abundanceAdd or 0)
		constituents[i] = {material = materialsSetEntry.material, amount = amount}
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

function tiles:generateTile(chunk, x, y)
	-- TODO
end

local function getGrassTargetHealth(tile, subLayerIndex)
	local x, y = tile.globalTileX, tile.globalTileY
	-- TODO: not hardcoded (grass loam requirement, grass water requirement...)
	-- grass should only be able to grow on toppings with lumpsPerLayer lumps
	local loamAmount, waterAmount = 0, 0
	if subLayerIndex == 1 and tile.topping then
		local lumps = tile.topping.lumps
		local topLump = lumps.compressedToOne and lumps.compressionLump or lumps[consts.lumpsPerLayer]
		for _, entry in ipairs(topLump.constituents) do
			if entry.material.name == "loam" then
				loamAmount = entry.amount
			elseif entry.material.name == "water" then
				waterAmount = entry.amount
			end
		end
	else
		-- NOTE: Could have even more complex code where grass passes through grates and the like
		for _, entry in ipairs(tile.superTopping.subLayers[subLayerIndex - 1]) do
			if entry.material.name == "loam" then
				loamAmount = entry.amount
			elseif entry.material.name == "water" then
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
	-- Only values relevant to fixed update, and only values dependent on the tile's lumps
	updateGrassTargetHealths(tile)
end

function tiles:tickTile(tile, dt)
	local changedSuperToppingRendering
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
				local toDelete
				if subLayer.type == "grass" then
					-- Delete grass of amount 0
					if subLayer.lump.grassAmount == 0 then
						toDelete = true
					else
						local grassMaterial = subLayer.lump.constituents[1].material
						
						-- Update health
						local prevHealth = subLayer.lump.grassHealth
						local targetHealth = subLayer.grassTargetHealth
						if targetHealth > subLayer.lump.grassHealth then -- Add to health using healthIncreaseRate
							subLayer.lump.grassHealth = math.min(targetHealth, subLayer.lump.grassHealth + grassMaterial.healthIncreaseRate * effectiveDt)
							changedSuperToppingRendering = true
						elseif targetHealth < subLayer.lump.grassHealth then -- Subtract from health using healthDecreaseRate
							subLayer.lump.grassHealth = math.min(targetHealth, subLayer.lump.grassHealth - grassMaterial.healthDecreaseRate * effectiveDt)
							changedSuperToppingRendering = true
						end
						
						-- Update amount
						-- TODO: Grass amount of grass with health x should approach x.
						-- Speed of approach should be multiplied with 1 - health downwards and with health upwards.
						-- Check docs/materials.md.
						local targetAmount = math.max(0, math.min(1, subLayer.lump.grassHealth + grassMaterial.targetGrassAmountAdd))
						if targetAmount > subLayer.lump.grassAmount then -- Add to amount using grassHealth and growthRate
							subLayer.lump.grassAmount = math.min(targetAmount, subLayer.lump.grassAmount + grassMaterial.growthRate * subLayer.lump.grassHealth * effectiveDt)
							changedSuperToppingRendering = true
						elseif targetAmount < subLayer.lump.grassAmount then -- Subtract from amount using 1 - grassHealth and decayRate
							subLayer.lump.grassAmount = math.max(targetAmount, subLayer.lump.grassAmount - grassMaterial.decayRate * (1 - subLayer.lump.grassHealth) * effectiveDt)
							changedSuperToppingRendering = true
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
	if changedSuperToppingRendering then
		self:updateTileRendering(tile)
	end
	tile.lastTimeTicked = currentTime
end

function tiles:decompressLumps(lumps)
	assert(lumps.compressedToOne, "Can't decompress uncompressed lumps table")
	lumps.compressedToOne = nil
	lumps[1] = lumps.compressionLump
	for i = 2, consts.lumpsPerLayer do
		lumps[i] = {}
		for k, v in pairs(lumps.compressionLump) do
			lumps[i][k] = v
		end
	end
	lumps.compressionLump = nil
end

return tiles
