local boilerplate = require("lib.love-game-boilerplate-lib")
local concord = require("lib.concord")

local consts = require("consts")

local hud = concord.system({players = {"player"}})

function hud:init()
	
end

function hud:draw(lerp, dt, performance)
	player = self.players[1]
	if not player then
		return
	end
	
	love.graphics.setCanvas(boilerplate.hudCanvas)
	love.graphics.clear()
	-- love.graphics.print(
	-- 	"X: " .. math.round(player.position.interpolated.x) .. "\n" ..
	-- 	"Y: " .. math.round(player.position.interpolated.y) .. "\n" ..
	-- 	"Speed: " .. math.round(#player.velocity.value)
	-- )
	love.graphics.setCanvas()
end

return hud
