local concord = require("lib.concord")
local vec2 = require("lib.mathsies").vec2
local boilerplate = require("lib.love-game-boilerplate-lib")

local wills = concord.system({wills = {"will"}, willPlayers = {"will", "player"}})

function wills:fixedUpdate(dt)
	for _, e in ipairs(self.wills) do
		for k in pairs(e.will) do
			e.will[k] = nil -- What if you remove both player and AI from an object? It can't just keep moving in one direction...
			-- If this is unperformant, then it could be replaced with checking for AI or player or any other "will source" before using will.
		end
	end
	
	for _, e in ipairs(self.willPlayers) do
		local will = e.will
		will.accel = vec2()
		if boilerplate.input.didFixedCommand("moveForward") then
			will.accel.y = will.accel.y - 10
		end
		if boilerplate.input.didFixedCommand("moveBackward") then
			will.accel.y = will.accel.y + 10
		end
		if boilerplate.input.didFixedCommand("moveLeft") then
			will.accel.x = will.accel.x - 10
		end
		if boilerplate.input.didFixedCommand("moveRight") then
			will.accel.x = will.accel.x + 10
		end
	end
end

return wills
