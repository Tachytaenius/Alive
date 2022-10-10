local concord = require("lib.concord")
local vec2 = require("lib.mathsies").vec2
local boilerplate = require("lib.love-game-boilerplate-lib")

local consts = require("consts")

local wills = concord.system({
	wills = {"will"},
	willPlayers = {"will", "player"}
})

function wills:fixedUpdate(dt)
	for _, e in ipairs(self.wills) do
		for k in pairs(e.will) do
			e.will[k] = nil -- What if you remove both player and AI from an object? It can't just keep moving in one direction...
			-- If this is unperformant, then it could be replaced with checking for AI or player or any other "will source" before using will.
		end
	end
	
	for _, e in ipairs(self.willPlayers) do
		local will = e.will
		
		will.targetRelativeVelocityMultiplier = vec2()
		if boilerplate.input.checkFixedUpdateCommand("moveForward") then
			will.targetRelativeVelocityMultiplier.y = will.targetRelativeVelocityMultiplier.y - 1
		end
		if boilerplate.input.checkFixedUpdateCommand("moveBackward") then
			will.targetRelativeVelocityMultiplier.y = will.targetRelativeVelocityMultiplier.y + 1
		end
		if boilerplate.input.checkFixedUpdateCommand("moveLeft") then
			will.targetRelativeVelocityMultiplier.x = will.targetRelativeVelocityMultiplier.x - 1
		end
		if boilerplate.input.checkFixedUpdateCommand("moveRight") then
			will.targetRelativeVelocityMultiplier.x = will.targetRelativeVelocityMultiplier.x + 1
		end
		if #will.targetRelativeVelocityMultiplier > 0 then
			will.targetRelativeVelocityMultiplier = vec2.normalise(will.targetRelativeVelocityMultiplier)
		end
		
		will.targetAngularVelocityMultiplier = math.max(-1, math.min(1, boilerplate.fixedMouseDx * boilerplate.settings.mouse.turnSensitivity * consts.turningMouseMovementMultiplier))
	end
end

return wills
