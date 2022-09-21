local concord = require("lib.concord")
local vec2 = require("lib.mathsies").vec2

local walking = concord.system({walkers = {"will", "gait", "velocity", "grounded"}})

local function handleAxis(current, target, acceleration, dt)
	if acceleration > 0 then
		return math.min(target, current + acceleration * dt)
	elseif acceleration < 0 then
		return math.max(target, current + acceleration * dt)
	end
	
	return current
end

function walking:fixedUpdate(dt)
	for _, e in ipairs(self.walkers) do
		if e.will.targetVelocityMultiplier then
			local targetVelocity = e.will.targetVelocityMultiplier * e.gait.maxSpeed
			
			local difference = targetVelocity - e.velocity.value
			local direction
			if #difference > 0 then
				direction = vec2.normalise(difference)
			else
				direction = difference
			end
			local accelerationDistribution = direction * e.gait.acceleration -- So that you don't get to use all of acceleration on both axes
			
			-- e.velocity.value = vec2.clone(e.velocity.value) -- The test below returns 0 for acceleration this tick without this line
			e.velocity.value.x = handleAxis(e.velocity.value.x, targetVelocity.x, e.gait.acceleration * math.sign(targetVelocity.x - e.velocity.value.x), dt)
			e.velocity.value.y = handleAxis(e.velocity.value.y, targetVelocity.y, e.gait.acceleration * math.sign(targetVelocity.y - e.velocity.value.y), dt)
			
			-- Test that acceleration is never (beyond acceptable floating point error) greater than e.gait.acceleration
			-- if e.velocity.previousValue then
			-- 	print(e.gait.acceleration, #(e.velocity.value - e.velocity.previousValue))
			-- end
		end
	end
end

return walking
