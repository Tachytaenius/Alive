local boilerplate = require("lib.love-game-boilerplate-lib")
local concord = require("lib.concord")

local consts = require("consts")

local rendering = concord.system({players = {"player"}, sprites = {"position", "sprite"}})

function rendering:init()
	self.preCrushCanvas = love.graphics.newCanvas(consts.preCrushCanvasWidth, consts.preCrushCanvasHeight)
	-- self.crushShader = love.graphics.newShader("shaders/crush.glsl")
end

function rendering:draw(lerp, dt, performance)
	player = self.players[1]
	if not player then
		return
	end
	
	love.graphics.setCanvas(boilerplate.gameCanvas)
	love.graphics.clear(0, 0, 0, 1)
	love.graphics.translate(-player.position.lerpedValue.x, -player.position.lerpedValue.y)
	love.graphics.translate(boilerplate.config.canvasSystemWidth / 2, boilerplate.config.canvasSystemHeight / 2)
	for _, e in ipairs(self.sprites) do
		love.graphics.circle("fill", e.position.lerpedValue.x, e.position.lerpedValue.y, e.sprite.radius)
	end
	love.graphics.origin()
	love.graphics.setCanvas()
end

return rendering
