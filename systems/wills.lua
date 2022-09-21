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
		will.targetVelocityMultiplier = vec2()
		if boilerplate.input.checkFixedUpdateCommand("moveForward") then
			will.targetVelocityMultiplier.y = will.targetVelocityMultiplier.y - 10
		end
		if boilerplate.input.checkFixedUpdateCommand("moveBackward") then
			will.targetVelocityMultiplier.y = will.targetVelocityMultiplier.y + 10
		end
		if boilerplate.input.checkFixedUpdateCommand("moveLeft") then
			will.targetVelocityMultiplier.x = will.targetVelocityMultiplier.x - 10
		end
		if boilerplate.input.checkFixedUpdateCommand("moveRight") then
			will.targetVelocityMultiplier.x = will.targetVelocityMultiplier.x + 10
		end
		if #will.targetVelocityMultiplier > 0 then
			will.targetVelocityMultiplier = vec2.normalise(will.targetVelocityMultiplier)
		end
	end
end

return wills
