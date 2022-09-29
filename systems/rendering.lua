local boilerplate = require("lib.love-game-boilerplate-lib")
local concord = require("lib.concord")

local consts = require("consts")

local rendering = concord.system({players = {"player", "vision"}, sprites = {"position", "sprite"}})

function rendering:sendConstantsToShaders()
	self.crushAndClipShader:send("inputCanvasSize", {self.preCrushCanvas:getDimensions()})
	self.textureShader:send("noiseTexture", boilerplate.assets.noiseTexture.value)
	self.textureShader:send("noiseTextureSize", {boilerplate.assets.noiseTexture.value:getDimensions()})
end

function rendering:init()
	self.preCrushCanvas = love.graphics.newCanvas(consts.preCrushCanvasWidth, consts.preCrushCanvasHeight)
	self.preCrushCanvas:setWrap("clampzero")
	
	self.dummyImage = love.graphics.newImage(love.image.newImageData(1, 1))
	
	self.crushAndClipShader = love.graphics.newShader("shaders/crushAndClip.glsl")
	self.textureShader = love.graphics.newShader("shaders/texture.glsl")
	self:sendConstantsToShaders()
	
	self.changedTiles = {}
end

function rendering:drawSprite(e)
	love.graphics.circle("fill", e.position.lerpedValue.x, e.position.lerpedValue.y, e.sprite.radius)
end

local function setTileMeshVertices(mesh, iBase, x, y, col1, col2, col3, noiseSize, noiseContrast, noiseBrightness, fullness)
	mesh:setVertex(iBase,
		x * consts.tileWidth, y * consts.tileHeight,
		col1, col2, col3,
		noiseSize, noiseContrast, noiseBrightness, fullness
	)
	mesh:setVertex(iBase + 1,
		(x + 1) * consts.tileWidth, y * consts.tileHeight,
		col1, col2, col3,
		noiseSize, noiseContrast, noiseBrightness, fullness
	)
	mesh:setVertex(iBase + 2,
		x * consts.tileWidth, (y + 1) * consts.tileHeight,
		col1, col2, col3,
		noiseSize, noiseContrast, noiseBrightness, fullness
	)
	
	mesh:setVertex(iBase + 3,
		x * consts.tileWidth, (y + 1) * consts.tileHeight,
		col1, col2, col3,
		noiseSize, noiseContrast, noiseBrightness, fullness
	)
	mesh:setVertex(iBase + 4,
		(x + 1) * consts.tileWidth, y * consts.tileHeight,
		col1, col2, col3,
		noiseSize, noiseContrast, noiseBrightness, fullness
	)
	mesh:setVertex(iBase + 5,
		(x + 1) * consts.tileWidth, (y + 1) * consts.tileHeight,
		col1, col2, col3,
		noiseSize, noiseContrast, noiseBrightness, fullness
	)
end

function rendering:fixedUpdate(dt)
	for _, tile in ipairs(self.changedTiles) do
		local localTileX, localTileY = tile.localTileX, tile.localTileY
		local globalTileX, globalTileY = tile.globalTileX, tile.globalTileY
		local chunk = tile.chunk
		local iBase = (localTileX + localTileY * consts.chunkWidth) * 6 + 1
		
		-- Update topping
		if tile.topping then
			local
				col1, col2, col3,
				noiseSize, noiseContrast, noiseBrightness, fullness
			=
				tile.topping.r, tile.topping.g, tile.topping.b,
				tile.topping.noiseSize, tile.topping.noiseContrast, tile.topping.noiseBrightness, 1
			
			setTileMeshVertices(chunk.toppingMesh, iBase, globalTileX, globalTileY,
				col1, col2, col3,
				noiseSize, noiseContrast, noiseBrightness, fullness
			)
		else
			for i = 0, 5 do
				self.toppingMesh:setVertex(iBase + i) -- nil all
			end
		end
		
		-- Update super topping
		if tile.superTopping then
			if tile.superTopping.type == "wall" then
				local
					col1, col2, col3,
					noiseSize, noiseContrast, noiseBrightness, fullness
				=
					tile.superTopping.r, tile.superTopping.g, tile.superTopping.b,
					tile.superTopping.noiseSize, tile.superTopping.noiseContrast, tile.superTopping.noiseBrightness, tile.superTopping.fullness
				
				setTileMeshVertices(chunk.superToppingMeshes[1], iBase, globalTileX, globalTileY,
					col1, col2, col3,
					noiseSize, noiseContrast, noiseBrightness, fullness
				)
				
				for j = 2, consts.maxSubLayers do
					for i = 0, 5 do
						self.superToppingMeshes[i]:setVertex(iBase + i) -- nil all
					end
				end
			else -- "layers"
				for j = 1, consts.maxSubLayers do
					local subLayer = tile.superTopping.subLayers[j]
					if subLayer then
						local
							col1, col2, col3,
							noiseSize, noiseContrast, noiseBrightness, fullness
						=
							subLayer.r, subLayer.g, subLayer.b,
							subLayer.noiseSize, subLayer.noiseContrast, subLayer.noiseBrightness, subLayer.fullness
						
						setTileMeshVertices(chunk.superToppingMeshes[j], iBase, globalTileX, globalTileY,
							col1, col2, col3,
							noiseSize, noiseContrast, noiseBrightness, fullness
						)
					else
						for i = 0, 5 do
							chunk.superToppingMeshes[j]:setVertex(iBase + i) -- nil all
						end
					end
				end
			end
		else
			for j = 1, consts.maxSubLayers do
				for i = 0, 5 do
					chunk.superToppingMeshes[j]:setVertex(iBase + i) -- nil all
				end
			end
		end
	end
	self.changedTiles = {}
end

function rendering:draw(lerp, dt, performance)
	local player = self.players[1]
	if not player then
		return
	end
	
	assert(player.vision.renderDistance <= consts.chunkProcessingRadius, "Player vision is greater than chunk processing radius")
	
	local sensingCircleRadius = 30 -- TODO
	local viewPadding = 4 -- TODO
	local fov = 7 * math.tau / 16 -- TODO
	
	local preCrushPlayerPosX, preCrushPlayerPosY = self.preCrushCanvas:getWidth() / 2, self.preCrushCanvas:getHeight() - (sensingCircleRadius + viewPadding)
	
	love.graphics.setCanvas(self.preCrushCanvas)
	love.graphics.clear()
	love.graphics.translate(preCrushPlayerPosX, preCrushPlayerPosY)
	love.graphics.rotate(-player.angle.lerpedValue)
	love.graphics.translate(-player.position.lerpedValue.x, -player.position.lerpedValue.y)
	
	local normalHeightSprites = self.sprites -- TODO
	
	local mapSystem = self:getWorld().map
	
	-- Draw toppings
	love.graphics.setShader(self.textureShader)
	local x1, x2, y1, y2 = mapSystem:getChunkIterationStartEnd(player, player.vision.renderDistance)
	for x = x1, x2 do
		for y = y1, y2 do
			if mapSystem:chunkPositionIsInRadius(x, y, player, player.vision.renderDistance) then
				local chunk = mapSystem:getLoadedChunk(x, y)
				assert(chunk, "Missing chunk in draw radius at " .. x .. ", " .. y)
				love.graphics.draw(chunk.toppingMesh)
			end
		end
	end
	love.graphics.setShader()
	
	-- Draw entities in ditches
	for _, e in ipairs(normalHeightSprites) do
		self:drawSprite(e)
	end
	
	-- Draw superToppings
	love.graphics.setShader(self.textureShader)
	local x1, x2, y1, y2 = mapSystem:getChunkIterationStartEnd(player, player.vision.renderDistance)
	for x = x1, x2 do
		for y = y1, y2 do
			if mapSystem:chunkPositionIsInRadius(x, y, player, player.vision.renderDistance) then
				local chunk = mapSystem:getLoadedChunk(x, y)
				assert(chunk, "Missing chunk in draw radius at " .. x .. ", " .. y)
				for _, mesh in ipairs(chunk.superToppingMeshes) do
					love.graphics.draw(mesh)
				end
			end
		end
	end
	love.graphics.setShader()
	
	-- Draw entities at normal height
	for _, e in ipairs(normalHeightSprites) do
		self:drawSprite(e)
	end
	
	love.graphics.origin()
	love.graphics.setCanvas(boilerplate.gameCanvas)
	love.graphics.clear(0, 0, 0, 1)
	love.graphics.setShader(self.crushAndClipShader)
	
	local crushCentreX, crushCentreY = preCrushPlayerPosX, preCrushPlayerPosY
	local crushStart = consts.crushStart
	local crushEnd = consts.crushEnd
	local power = math.log(player.vision.renderDistance / crushStart) / math.log(crushEnd / crushStart)
	self.crushAndClipShader:send("crushCentre", {crushCentreX, crushCentreY})
	self.crushAndClipShader:send("crushStart", crushStart)
	self.crushAndClipShader:send("crushEnd", crushEnd)
	self.crushAndClipShader:send("sensingCircleRadius", sensingCircleRadius)
	self.crushAndClipShader:send("fov", fov)
	self.crushAndClipShader:send("power", power)
	love.graphics.draw(self.preCrushCanvas,
		boilerplate.gameCanvas:getWidth() / 2 - crushCentreX,
		boilerplate.gameCanvas:getHeight() - self.preCrushCanvas:getHeight()
	)
	
	love.graphics.setCanvas()
	love.graphics.origin()
	love.graphics.setShader()
end

return rendering
