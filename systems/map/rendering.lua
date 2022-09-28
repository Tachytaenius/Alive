local consts = require("consts")

local rendering = {}

function rendering:makeChunkMeshes(chunk)
	local tileMeshVertexCount = consts.chunkWidth * consts.chunkHeight * 6
	chunk.toppingMesh = love.graphics.newMesh(consts.tileMeshVertexFormat, tileMeshVertexCount, "triangles", "dynamic")
	chunk.superToppingMeshes = {}
	for i = 1, consts.maxSubLayers do
		chunk.superToppingMeshes[i] = love.graphics.newMesh(consts.tileMeshVertexFormat, tileMeshVertexCount, "triangles", "dynamic")
	end
end

local function getGrassNoiseFullness(subLayer)
	local grassMaterial = subLayer.lump.constituents[1].material
	local fullness1 = grassMaterial.fullness1 or 1
	return fullness1 == 0 and 1 or subLayer.lump.grassAmount / fullness1 -- NOTE: Does not need to be capped at 1
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

function rendering:updateTileRendering(tile)
	local x, y = tile.globalTileX, tile.globalTileY
	
	-- Update topping
	if tile.topping then
		local materialAmount = {}
		if tile.topping.lumps.compressedToOne then
			for _, constituent in ipairs(tile.topping.lumps.compressionLump.constituents) do
				local material = constituent.material
				materialAmount[material] = (materialAmount[material] or 0) + constituent.amount * consts.lumpsPerLayer
			end
		else
			for _, lump in ipairs(tile.topping.lumps) do
				for _, constituent in ipairs(lump.constituents) do
					local material = constituent.material
					materialAmount[material] = (materialAmount[material] or 0) + constituent.amount
				end
			end
		end
		calculateConstituentDrawFields(materialAmount, tile.topping)
	end
	
	-- Update super topping
	if tile.superTopping then
		if tile.superTopping.type == "layers" then
			for _, subLayer in ipairs(tile.superTopping.subLayers) do
				local materialAmount = {}
				for _, constituent in ipairs(subLayer.lump.constituents) do
					materialAmount[constituent.material] = constituent.amount
				end
				calculateConstituentDrawFields(materialAmount, subLayer, subLayer.type == "grass" and subLayer.lump.grassHealth)
				subLayer.fullness = getGrassNoiseFullness(subLayer)
			end
		else -- type == "wall"
			local materialAmount = {}
			if tile.superTopping.lumps.compressedToOne then
				for _, constituent in ipairs(tile.superTopping.compressionLump.constituents) do
					local material = constituent.material
					materialAmount[material] = (materialAmount[material] or 0) + constituent.amount * consts.lumpsPerLayer
				end
			else
				for _, lump in ipairs(tile.superTopping.lumps) do
					for _, constituent in ipairs(lump.constituents) do
						local material = constituent.material
						materialAmount[material] = (materialAmount[material] or 0) + constituent.amount
					end
				end
			end
			calculateConstituentDrawFields(materialAmount, tile.superTopping)
		end
	end
	
	local changedTiles = self:getWorld().rendering.changedTiles
	changedTiles[#changedTiles + 1] = tile
end

return rendering
