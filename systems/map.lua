local concord = require("lib.concord")
local list = require("lib.list")

local registry = require("registry")
local consts = require("consts")

local map = concord.system({})

function map:newWorld(width, height)
	self.width, self.height = width, height
	
	self.soilMaterials = {
		{material = registry.materials.byName.loam, abundanceMultiply = 14, noiseWidth = 50, noiseHeight = 50},
		{material = registry.materials.byName.clay, abundanceMultiply = 13, noiseWidth = 50, noiseHeight = 50},
		{material = registry.materials.byName.sand, abundanceMultiply = 5, noiseWidth = 50, noiseHeight = 50},
		{material = registry.materials.byName.silt, abundanceMultiply = 7, noiseWidth = 50, noiseHeight = 50},
		{material = registry.materials.byName.water, abundanceMultiply = 0, abundanceAdd = 10}
	}
	
	local loadedChunks = list()
	self.loadedChunks = loadedChunks
	local chunks = {}
	self.chunks = chunks
	for chunkX = 0, width - 1 do
		local chunksColumn = {}
		chunks[chunkX] = chunksColumn
		for chunkY = 0, height - 1 do
			local chunk = {
				-- tickCursorX = 0, tickCursorY = 0 -- NOTE: For unused non-random ticks
			}
			loadedChunks:add(chunk)
			-- Now make the tiles
			local tiles = {}
			chunk.tiles = tiles
			for localTileX = 0, consts.chunkWidth - 1 do
				local tilesColumn = {}
				tiles[localTileX] = tilesColumn
				for localTileY = 0, consts.chunkHeight - 1 do
					local globalTileX, globalTileY = chunkX * consts.chunkWidth + localTileX, chunkY * consts.chunkHeight + localTileY
					local tile = {
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
					self:updateToppingRendering(tile)
					
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
					self:updatePrecalculatedValues(tile)
					newSubLayer.grassHealth = newSubLayer.grassTargetHealth
					newSubLayer.grassAmount	= math.max(0, math.min(1, newSubLayer.grassHealth + grassMaterial.targetGrassAmountAdd))
					self:updateSuperToppingRendering(tile, true) -- True to suppress add to changed tiles because updateToppingRendering already did that
				end
			end
		end
	end
end

local function getGrassTargetHealth(tile, subLayerIndex)
	local x, y = tile.globalTileX, tile.globalTileY
	-- TODO: not hardcoded (grass loam requirement, grass water requirement...)
	-- grass should only be able to grow on toppings with lumpsPerLayer lumps
	local loamAmount, waterAmount = 0, 0
	if subLayerIndex == 1 and tile.topping then
		for _, entry in ipairs(tile.topping.lumps[consts.lumpsPerLayer].constituents) do
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

function map:updatePrecalculatedValues(tile)
	-- Initial grass health and amount is based on a value set here, added to the tile after the call of this function
	-- Might have to call this function twice if grass health or amount are used in this function
	updateGrassTargetHealths(tile)
end

local function calculateConstituentDrawFields(materialAmount, tableToWriteTo, grassHealth)
	local weightTotal = 0
	local r, g, b, noiseSize, contrast, brightness = 0, 0, 0, 0, 0, 0
	for material, amount in pairs(materialAmount) do
		local weight = amount * (material.visualWeight or 1)
		weightTotal = weightTotal + weight
		local materialRed = material.colour[1]
		local materialGreen = material.colour[2]
		local materialBlue = material.colour[3]
		if grassHealth and material.deadColour then
			materialRed = math.lerp(material.deadColour[1], materialRed, grassHealth)
			materialGreen = math.lerp(material.deadColour[2], materialGreen, grassHealth)
			materialBlue = math.lerp(material.deadColour[3], materialBlue, grassHealth)
		end
		r = r + materialRed * weight
		g = g + materialGreen * weight
		b = b + materialBlue * weight
		noiseSize = noiseSize + (material.noiseSize or 10) * weight
		contrast = contrast + (material.contrast or 0.5) * weight
		brightness = brightness + (material.brightness or 0.5) * weight
	end
	tableToWriteTo.r = r / weightTotal
	tableToWriteTo.g = g / weightTotal
	tableToWriteTo.b = b / weightTotal
	tableToWriteTo.noiseSize = math.max(consts.minimumTextureNoiseSize,
		math.floor((noiseSize / weightTotal) / consts.textureNoiseSizeIrresolution) * consts.textureNoiseSizeIrresolution
	)
	tableToWriteTo.contrast = contrast / weightTotal
	tableToWriteTo.brightness = brightness / weightTotal
end

function map:updateToppingRendering(tile, suppressAddToChangedTiles)
	local x, y = tile.globalTileX, tile.globalTileY
	local tileTopping = tile.topping
	if not tileTopping then
		return
	end
	local materialAmount = {}
	for _, lump in ipairs(tileTopping.lumps) do
		for _, constituent in ipairs(lump.constituents) do
			local material = constituent.material
			materialAmount[material] = (materialAmount[material] or 0) + constituent.amount
		end
	end
	calculateConstituentDrawFields(materialAmount, tileTopping)
	if not suppressAddToChangedTiles then
		local changedTiles = self:getWorld().rendering.changedTiles
		changedTiles[#changedTiles + 1] = tile
	end
end

local function getGrassNoiseFullness(subLayer)
	local grassMaterial = subLayer.lump.constituents[1].material
	local fullness1 = grassMaterial.fullness1 or 1
	return fullness1 == 0 and 1 or subLayer.grassAmount / fullness1 -- NOTE: Does not need to be capped at 1
end

local function subLayerFullyOccludes(subLayer)
	if subLayer.type == "grass" then
		if getGrassNoiseFullness(subLayer) >= 1 then
			return true -- TODO: When transparent materialas are added, wrap this return in another check for alpha
		end
		return false
	else
		error("Haven't implemented subLayerFullyOccludes for subLayer type " .. subLayer.type)
	end
end

local function wallFullyOccludes(superTopping)
	assert(superTopping.type == "wall", "Tried to check wall occlusion of non-wall-type super topping")
	return true -- TODO: Alpha check
end

function map:updateSuperToppingRendering(tile, suppressAddToChangedTiles)
	local tileSuperTopping = tile.superTopping
	if not tileSuperTopping then
		return
	end
	if tileSuperTopping.type == "layers" then
		local anySubLayerFullyOccludes
		for _, subLayer in ipairs(tileSuperTopping.subLayers) do
			local materialAmount = {}
			for _, constituent in ipairs(subLayer.lump.constituents) do
				materialAmount[constituent.material] = constituent.amount
			end
			calculateConstituentDrawFields(materialAmount, subLayer, subLayer.type == "grass" and subLayer.grassHealth)
			
			subLayer.fullness = getGrassNoiseFullness(subLayer)
			
			local occludes = subLayerFullyOccludes(subLayer)
			subLayer.occludes = occludes
			anySubLayerFullyOccludes = anySubLayerFullyOccludes or occludes
		end
		tileSuperTopping.occludes = anySubLayerFullyOccludes
	else -- type == "wall"
		local materialAmount = {}
		for _, lump in ipairs(tileSuperTopping.lumps) do
			for _, constituent in ipairs(lump.constituents) do
				local material = constituent.material
				materialAmount[material] = (materialAmount[material] or 0) + constituent.amount
			end
		end
		calculateConstituentDrawFields(materialAmount, tileSuperTopping)
		tileSuperTopping.occludes = wallFullyOccludes(tileSuperTopping)
	end
	if not suppressAddToChangedTiles then
		local changedTiles = self:getWorld().rendering.changedTiles
		changedTiles[#changedTiles + 1] = tile
	end
end

function map:generateConstituents(x, y, materialsSet)
	-- All constituents must add up to const.lumpConstituentsTotal
	local constituents = {}
	
	-- Get base weights
	local total1 = 0
	for i, materialsSetEntry in pairs(materialsSet) do
		local noise = love.math.noise(
			x / (materialsSetEntry.noiseWidth or 1),
			y / (materialsSetEntry.noiseHeight or 1),
			materialsSetEntry.material.id
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

function map:tickTile(tile, dt)
	local changedSuperToppingRendering
	local currentTickTimer = self:getWorld().superWorld.tickTimer
	local effectiveDt = dt * tonumber(currentTickTimer - (tile.lastTickTimer or currentTickTimer)) -- tick timer is an FFI uint64
	-- Update grass
	if tile.superTopping then
		if tile.superTopping.type == "layers" then
			for i, subLayer in ipairs(tile.superTopping.subLayers) do
				if subLayer.type == "grass" then
					local grassMaterial = subLayer.lump.constituents[1].material
					
					-- Update health
					local prevHealth = subLayer.grassHealth
					local targetHealth = subLayer.grassTargetHealth
					if targetHealth > subLayer.grassHealth then -- Add to health using healthIncreaseRate
						subLayer.grassHealth = math.min(targetHealth, subLayer.grassHealth + grassMaterial.healthIncreaseRate * effectiveDt)
						changedSuperToppingRendering = true
					elseif targetHealth < subLayer.grassHealth then -- Subtract from health using healthDecreaseRate
						subLayer.grassHealth = math.min(targetHealth, subLayer.grassHealth - grassMaterial.healthDecreaseRate * effectiveDt)
						changedSuperToppingRendering = true
					end
					
					-- Update amount
					-- TODO: Grass amount of grass with health x should approach x.
					-- Speed of approach should be multiplied with 1 - health downwards and with health upwards.
					-- Check docs/materials.md.
					local targetAmount = math.max(0, math.min(1, subLayer.grassHealth + grassMaterial.targetGrassAmountAdd))
					if targetAmount > subLayer.grassAmount then -- Add to amount using grassHealth and growthRate
						subLayer.grassAmount = math.min(targetAmount, subLayer.grassAmount + grassMaterial.growthRate * subLayer.grassHealth * effectiveDt)
						changedSuperToppingRendering = true
					elseif targetAmount < subLayer.grassAmount then -- Subtract from amount using 1 - grassHealth and decayRate
						subLayer.grassAmount = math.max(targetAmount, subLayer.grassAmount - grassMaterial.decayRate * (1 - subLayer.grassHealth) * effectiveDt)
						changedSuperToppingRendering = true
					end
				end
			end
		end
	end
	if changedSuperToppingRendering then
		self:updateSuperToppingRendering(tile)
	end
	tile.lastTickTimer = currentTickTimer
end

function map:fixedUpdate(dt)
	local rng = self:getWorld().superWorld.rng
	for chunk in self.loadedChunks:elements() do
		for i = 1, consts.randomTicksPerChunkPerTick do
			local x = rng:random(0, consts.chunkWidth - 1)
			local y = rng:random(0, consts.chunkHeight - 1)
			self:tickTile(chunk.tiles[x][y], dt)
		end
	end
	-- NOTE: For unused non-random ticks
	-- for chunk in self.loadedChunks:elements() do
	-- 	local x, y = chunk.tickCursorX, chunk.tickCursorY
	-- 	for i = 1, consts.tileTicksPerChunkPerTick do
	-- 		self:tickTile(chunk.tiles[x][y], dt)
	-- 		x = x + 1
	-- 		if x == consts.chunkWidth then
	-- 			x = 0
	-- 			y = y + 1
	-- 		end
	-- 		if y == consts.chunkHeight then
	-- 			y = 0
	-- 		end
	-- 	end
	-- 	chunk.tickCursorX, chunk.tickCursorY = x, y
	-- end
end

function map:validate()
	-- TODO: Go over every tile and check that the structure is correct, and error if not
end

function map:mine(tile, layerName, subLayerIndex)
	if layerName == "topping" then
		-- TODO: mine topping
	else -- layerName == "superTopping"
		if tile.superTopping.type == "wall" then
			-- TODO: mine super topping wall
		else -- tile.superTopping.type == "subLayers"
			local subLayer = tile.superTopping.subLayers[subLayerIndex]
			-- TODO: mine super topping sub-layer
		end
	end
end

return map
