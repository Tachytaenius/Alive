local boilerplate = require("lib.love-game-boilerplate-lib")
local concord = require("lib.concord")
local vec2 = require("lib.mathsies").vec2

local consts = require("consts")

local rendering = concord.system({players = {"position", "player", "vision"}, sprites = {"position", "sprite"}, lights = {"position", "light"}})

function rendering:sendConstantsToShaders()
	self.crushAndClipShader:send("inputCanvasSize", {consts.preCrushCanvasWidth, consts.preCrushCanvasHeight})
	
	self.textureShader:send("noiseTexture", boilerplate.assets.noiseTexture.value)
	self.textureShader:send("noiseTextureSize", {boilerplate.assets.noiseTexture.value:getDimensions()})
	
	self.lightingShader:send("canvasSize", {consts.preCrushCanvasWidth, consts.preCrushCanvasHeight})
end

function rendering:init()
	self.albedoCanvas = love.graphics.newCanvas(consts.preCrushCanvasWidth, consts.preCrushCanvasHeight)
	self.lightInfoCanvas = love.graphics.newCanvas(consts.preCrushCanvasWidth, consts.preCrushCanvasHeight)
	self.lightingCanvas = love.graphics.newCanvas(consts.preCrushCanvasWidth, consts.preCrushCanvasHeight)
	self.tileCanvasSetup = {
		self.albedoCanvas, self.lightInfoCanvas
	}
	if consts.linearFilterLightInfoCanvas then
		self.lightInfoCanvas:setFilter("linear", "linear")
	end
	
	self.crushAndClipShader = love.graphics.newShader("shaders/crushAndClip.glsl")
	self.textureShader = love.graphics.newShader("shaders/texture.glsl")
	self.lightingShader = love.graphics.newShader("shaders/lighting.glsl")
	self:sendConstantsToShaders()
	
	self.changedTiles = {}
end

function rendering:drawSprite(e)
	love.graphics.circle("fill", e.position.lerpedValue.x, e.position.lerpedValue.y, e.sprite.radius)
end

local function setTileMeshVertices(mesh, iBase, x, y, ...)
	mesh:setVertex(iBase, x * consts.tileWidth, y * consts.tileHeight, ...)
	mesh:setVertex(iBase + 1, (x + 1) * consts.tileWidth, y * consts.tileHeight, ...)
	mesh:setVertex(iBase + 2, x * consts.tileWidth, (y + 1) * consts.tileHeight, ...)
	
	mesh:setVertex(iBase + 3, x * consts.tileWidth, (y + 1) * consts.tileHeight, ...)
	mesh:setVertex(iBase + 4, (x + 1) * consts.tileWidth, y * consts.tileHeight, ...)
	mesh:setVertex(iBase + 5, (x + 1) * consts.tileWidth, (y + 1) * consts.tileHeight, ...)
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
				colourR, colourG, colourB,
				lightInfoColourR, lightInfoColourG, lightInfoColourB, lightInfoColourA,
				noiseSize, noiseContrast, noiseBrightness, fullness
			=
				tile.topping.r, tile.topping.g, tile.topping.b,
				nil, nil, nil, 0, -- This isn't a wall
				tile.topping.noiseSize, tile.topping.noiseContrast, tile.topping.noiseBrightness, 1
			
			setTileMeshVertices(chunk.toppingMesh, iBase, globalTileX, globalTileY,
				colourR, colourG, colourB,
				lightInfoColourR, lightInfoColourG, lightInfoColourB, lightInfoColourA,
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
					colourR, colourG, colourB,
					lightInfoColourR, lightInfoColourG, lightInfoColourB, lightInfoColourA,
					noiseSize, noiseContrast, noiseBrightness, fullness
				=
					tile.superTopping.r, tile.superTopping.g, tile.superTopping.b,
					tile.superTopping.lightInfoR, tile.superTopping.lightInfoG, tile.superTopping.lightInfoB, 1,
					tile.superTopping.noiseSize, tile.superTopping.noiseContrast, tile.superTopping.noiseBrightness, 1
				
				setTileMeshVertices(chunk.superToppingMeshes[1], iBase, globalTileX, globalTileY,
					colourR, colourG, colourB,
					lightInfoColourR, lightInfoColourG, lightInfoColourB, lightInfoColourA,
					noiseSize, noiseContrast, noiseBrightness, fullness
				)
				
				for j = 2, consts.maxSubLayers do -- Clear meshes used for sub-layers
					for i = 0, 5 do
						chunk.superToppingMeshes[j]:setVertex(iBase + i) -- nil all
					end
				end
			else -- "layers"
				for j = 1, consts.maxSubLayers do
					local subLayer = tile.superTopping.subLayers[j]
					if subLayer then
						local
							colourR, colourG, colourB,
							lightInfoColourR, lightInfoColourG, lightInfoColourB, lightInfoColourA,
							noiseSize, noiseContrast, noiseBrightness, fullness
						=
							subLayer.r, subLayer.g, subLayer.b,
							nil, nil, nil, 0, -- This isn't a wall
							subLayer.noiseSize, subLayer.noiseContrast, subLayer.noiseBrightness, subLayer.fullness
						
						setTileMeshVertices(chunk.superToppingMeshes[j], iBase, globalTileX, globalTileY,
							colourR, colourG, colourB,
							lightInfoColourR, lightInfoColourG, lightInfoColourB, lightInfoColourA,
							noiseSize, noiseContrast, noiseBrightness, fullness
						)
					else
						for i = 0, 5 do
							chunk.superToppingMeshes[j]:setVertex(iBase + i) -- nil all
						end
					end
				end
			end
		else -- No super topping
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
	
	local renderDistance = player.vision.maxViewDistance
	local sensingCircleRadius = 30 -- TODO
	local viewPadding = 4 -- TODO
	local fov = 7 * math.tau / 16 -- TODO
	local ambientLightR, ambientLightG, ambientLightB = 1, 1, 1 -- TODO
	
	assert(renderDistance <= consts.chunkProcessingRadius, "Player vision is greater than chunk processing radius")
	
	local preCrushPlayerPosX, preCrushPlayerPosY = consts.preCrushCanvasWidth / 2, consts.preCrushCanvasHeight - (sensingCircleRadius + viewPadding)
	
	love.graphics.translate(preCrushPlayerPosX, preCrushPlayerPosY)
	love.graphics.rotate(-player.angle.lerpedValue)
	love.graphics.translate(-player.position.lerpedValue.x, -player.position.lerpedValue.y)
	
	local normalHeightSprites = self.sprites -- TODO
	
	local mapSystem = self:getWorld().map
	
	love.graphics.setCanvas(self.albedoCanvas)
	love.graphics.clear()
	love.graphics.setCanvas(self.lightInfoCanvas)
	love.graphics.clear(1, 1, 1, 0)
	
	-- Draw toppings
	love.graphics.setCanvas(self.tileCanvasSetup)
	love.graphics.setShader(self.textureShader)
	local x1, x2, y1, y2 = mapSystem:getChunkIterationStartEnd(player, renderDistance)
	for x = x1, x2 do
		for y = y1, y2 do
			if mapSystem:chunkPositionIsInRadius(x, y, player, renderDistance) then
				local chunk = mapSystem:getLoadedChunk(x, y)
				assert(chunk, "Missing chunk in draw radius at " .. x .. ", " .. y)
				love.graphics.draw(chunk.toppingMesh)
			end
		end
	end
	
	-- Draw entities in ditches
	love.graphics.setCanvas(self.albedoCanvas)
	love.graphics.setShader()
	for _, e in ipairs(normalHeightSprites) do -- TODO
		self:drawSprite(e)
	end
	
	-- Draw superToppings
	love.graphics.setCanvas(self.tileCanvasSetup)
	love.graphics.setShader(self.textureShader)
	local x1, x2, y1, y2 = mapSystem:getChunkIterationStartEnd(player, renderDistance)
	for x = x1, x2 do
		for y = y1, y2 do
			if mapSystem:chunkPositionIsInRadius(x, y, player, renderDistance) then
				local chunk = mapSystem:getLoadedChunk(x, y)
				assert(chunk, "Missing chunk in draw radius at " .. x .. ", " .. y)
				for _, mesh in ipairs(chunk.superToppingMeshes) do
					love.graphics.draw(mesh)
				end
			end
		end
	end
	
	-- Draw entities at normal height
	love.graphics.setCanvas(self.albedoCanvas)
	love.graphics.setShader()
	for _, e in ipairs(normalHeightSprites) do
		self:drawSprite(e)
	end
	
	-- Switch to lights phase
	love.graphics.setCanvas(self.lightingCanvas)
	love.graphics.setShader()
	love.graphics.clear()
	love.graphics.push("all")
	love.graphics.setColor(ambientLightR, ambientLightG, ambientLightB)
	love.graphics.origin() -- We are replacing one canvas' contents with (a tinted version of) another's, so we don't want to use player position information et cetera
	love.graphics.draw(self.albedoCanvas) -- Draw tinted albedo canvas as ambient lighting
	love.graphics.pop()
	self.lightingShader:send("albedoCanvas", self.albedoCanvas)
	self.lightingShader:send("lightInfoCanvas", self.lightInfoCanvas)
	love.graphics.setShader(self.lightingShader)
	love.graphics.setBlendMode("add")
	
	-- Draw lights
	for _, e in ipairs(self.lights) do
		local posInWindowSpace = e.position.lerpedValue
		posInWindowSpace = posInWindowSpace - player.position.lerpedValue
		posInWindowSpace = vec2.rotate(posInWindowSpace, -player.angle.lerpedValue)
		posInWindowSpace = posInWindowSpace + vec2(preCrushPlayerPosX, preCrushPlayerPosY)
		self.lightingShader:send("lightOrigin", {vec2.components(posInWindowSpace)})
		love.graphics.setColor(e.light.r, e.light.g, e.light.b)
		love.graphics.draw(boilerplate.assets.lightInfluenceTexture.value, e.position.lerpedValue.x - e.light.radius, e.position.lerpedValue.y - e.light.radius, 0, e.light.radius * 2 / consts.lightInfluenceTextureSize)
	end
	love.graphics.setColor(1, 1, 1)
	
	-- Draw lighting canvas crushed
	love.graphics.setBlendMode("alpha")
	love.graphics.origin()
	love.graphics.setCanvas(boilerplate.gameCanvas)
	love.graphics.clear(0, 0, 0, 1)
	love.graphics.setShader(self.crushAndClipShader)
	local crushCentreX, crushCentreY = preCrushPlayerPosX, preCrushPlayerPosY
	local crushStart = consts.crushStart
	local crushEnd = consts.crushEnd
	local power = math.log(renderDistance / crushStart) / math.log(crushEnd / crushStart)
	self.crushAndClipShader:send("crushCentre", {crushCentreX, crushCentreY})
	self.crushAndClipShader:send("crushStart", crushStart)
	self.crushAndClipShader:send("crushEnd", crushEnd)
	self.crushAndClipShader:send("sensingCircleRadius", sensingCircleRadius)
	self.crushAndClipShader:send("fov", fov)
	self.crushAndClipShader:send("power", power)
	self.crushAndClipShader:send("fogFadeLength", boilerplate.settings.graphics.fogFadeLength)
	love.graphics.draw(self.lightingCanvas,
		boilerplate.gameCanvas:getWidth() / 2 - crushCentreX,
		boilerplate.gameCanvas:getHeight() - consts.preCrushCanvasHeight
	)
	
	-- Finish
	love.graphics.setCanvas()
	love.graphics.origin()
	love.graphics.setShader()
end

return rendering
