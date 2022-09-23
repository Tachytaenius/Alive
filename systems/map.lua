local concord = require("lib.concord")

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
	
	local tiles = {}
	self.tiles = tiles
	for x = 0, width - 1 do
		local column = {}
		tiles[x] = column
		for y = 0, height - 1 do
			local tile = {}
			column[y] = tile
			
			-- Generate topping
			tile.topping = {
				type = "solid",
				chunks = {}
			}
			local constituents = self:generateConstituents(x, y, self.soilMaterials)
			for _=1, consts.chunksPerLayer do
				local chunk = {}
				tile.topping.chunks[#tile.topping.chunks + 1] = chunk
				chunk.constituents = constituents
			end
			self:updateToppingDrawFields(x, y)
			
			-- Generate super topping
			tile.superTopping = {
				type = "layers",
				subLayers = {}
			}
			local grassHealth
			do -- TODO: not hardcoded (grass loam requirement, grass water requirement...)
				-- grass should only be able to grow on toppings with chunksPerLayer chunks
				local loamAmount, waterAmount = 0, 0
				for _, entry in ipairs(tile.topping.chunks[consts.chunksPerLayer].constituents) do
					if entry.material.name == "loam" then
						loamAmount = entry.amount
					elseif entry.material.name == "water" then
						waterAmount = entry.amount
					end
				end
				local loamFractionTarget = 0.3
				local waterFractionTarget = 0.3
				local loamHealthMultiplier = math.min(1, (loamAmount / consts.chunkConstituentsTotal) / loamFractionTarget)
				local waterHealthMultiplier = math.min(1, (waterAmount / consts.chunkConstituentsTotal) / waterFractionTarget)
				grassHealth = loamHealthMultiplier * waterHealthMultiplier
			end
			tile.superTopping.subLayers[1] = {
				type = "grass",
				chunk = {
					constituents = {
						{material = registry.materials.byName.grass, amount = consts.chunkConstituentsTotal}
					}
				},
				health = grassHealth
			}
			self:updateSuperToppingDrawFields(x, y)
		end
	end
end

local function calculateConstituentDrawFields(materialAmount, tableToWriteTo, health)
	local weightTotal = 0
	local r, g, b, noiseSize, contrast, brightness = 0, 0, 0, 0, 0, 0
	for material, amount in pairs(materialAmount) do
		local weight = amount * (material.visualWeight or 1)
		weightTotal = weightTotal + weight
		local materialRed = material.colour[1]
		local materialGreen = material.colour[2]
		local materialBlue = material.colour[3]
		if health and material.deadColour then
			materialRed = math.lerp(material.deadColour[1], materialRed, health)
			materialGreen = math.lerp(material.deadColour[2], materialGreen, health)
			materialBlue = math.lerp(material.deadColour[3], materialBlue, health)
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
		math.floor((noiseSize / weightTotal) / consts.textureNoiseSizeIrresolution) *
		consts.textureNoiseSizeIrresolution
	)
	tableToWriteTo.contrast = contrast / weightTotal
	tableToWriteTo.brightness = brightness / weightTotal
end

function map:updateToppingDrawFields(x, y)
	local tileTopping = self.tiles[x][y].topping
	if not tileTopping then
		return
	end
	local materialAmount = {}
	for _, chunk in ipairs(tileTopping.chunks) do
		for _, constituent in ipairs(chunk.constituents) do
			local material = constituent.material
			materialAmount[material] = (materialAmount[material] or 0) + constituent.amount
		end
	end
	calculateConstituentDrawFields(materialAmount, tileTopping)
end

function map:updateSuperToppingDrawFields(x, y)
	local tileSuperTopping = self.tiles[x][y].superTopping
	if not tileSuperTopping then
		return
	end
	if tileSuperTopping.type == "layers" then
		for _, subLayer in ipairs(tileSuperTopping.subLayers) do
			local materialAmount = {}
			for _, constituent in ipairs(subLayer.chunk.constituents) do
				materialAmount[constituent.material] = constituent.amount
			end
			calculateConstituentDrawFields(materialAmount, subLayer, subLayer.type == "grass" and subLayer.health)
		end
	else -- type == "wall"
		local materialAmount = {}
		for _, chunk in ipairs(tileSuperTopping.chunks) do
			for _, constituent in ipairs(chunk.constituents) do
				local material = constituent.material
				materialAmount[material] = (materialAmount[material] or 0) + constituent.amount
			end
		end
		calculateConstituentDrawFields(materialAmount, tileSuperTopping)
	end
end

function map:generateConstituents(x, y, materialsSet)
	-- All constituents must add up to const.chunkConstituentsTotal
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
		entry.amount = math.floor(consts.chunkConstituentsTotal * entry.amount / total1)
		total2 = total2 + entry.amount
	end
	
	-- Spread remainder (this could be done differently)
	local i = 1
	for _ = 1, consts.chunkConstituentsTotal - total2 do
		constituents[i].amount = constituents[i].amount + 1
		i = (i - 1 + 1) % #constituents + 1
	end
	
	-- Debug test
	-- local total3 = 0
	-- for i, entry in ipairs(constituents) do
	-- 	total3 = total3 + entry.amount
	-- end
	-- assert(total3 == consts.chunkConstituentsTotal)
	
	return constituents
end

function map:validate()
	-- TODO: Go over every tile and check that the structure is correct, and error if not
end

function map:mine(x, y, layerName, subLayerIndex)
	local tile = self.tiles[x][y]
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
