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
			
			local difference = targetVelocity - e.velocity.val
			local direction
			if #difference > 0 then
				direction = vec2.normalise(difference)
			else
				direction = difference
			end
			local accelerationDistribution = direction * e.gait.acceleration -- So that you don't get to use all of acceleration on both axes
			
			-- e.velocity.val = vec2.clone(e.velocity.val) -- The test below returns 0 for acceleration this tick without this line
			e.velocity.val.x = handleAxis(e.velocity.val.x, targetVelocity.x, e.gait.acceleration * math.sign(targetVelocity.x - e.velocity.val.x), dt)
			e.velocity.val.y = handleAxis(e.velocity.val.y, targetVelocity.y, e.gait.acceleration * math.sign(targetVelocity.y - e.velocity.val.y), dt)
			
			-- Test that acceleration is never (beyond acceptable floating point error) greater than e.gait.acceleration
			-- if e.velocity.pval then
			-- 	print(e.gait.acceleration, #(e.velocity.val - e.velocity.pval))
			-- end
		end
	end
end

return walking
