local concord = require("lib.concord")
local vec2 = require("lib.mathsies").vec2

local walking = concord.system({
	walkers = {"will", "gait", "velocity", "grounded"},
	turners = {"will", "angularGait", "angularVelocity", "grounded"}
})

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
		if e.will.targetRelativeVelocityMultiplier then
			local targetRelativeVelocity = e.will.targetRelativeVelocityMultiplier * e.gait.maxSpeed
			local angle = (e.angle and e.angle.value or 0) + math.tau / 4
			local relativeVelocity = vec2.detRotate(e.velocity.value, -angle)

			local difference = targetRelativeVelocity - relativeVelocity
			local direction
			if #difference > 0 then
				direction = vec2.normalise(difference)
			else
				direction = difference
			end
			local accelerationDistribution = direction * e.gait.acceleration -- So that you don't get to use all of acceleration on both axes

			relativeVelocity.x = handleAxis(relativeVelocity.x, targetRelativeVelocity.x, accelerationDistribution.x, dt)
			relativeVelocity.y = handleAxis(relativeVelocity.y, targetRelativeVelocity.y, accelerationDistribution.y, dt)

			e.velocity.value = vec2.detRotate(relativeVelocity, angle)
		end
	end

	for _, e in ipairs(self.turners) do
		if e.will.targetAngularVelocityMultiplier then
			local targetAngularVelocity = e.will.targetAngularVelocityMultiplier * e.angularGait.maxSpeed
			e.angularVelocity.value = handleAxis(e.angularVelocity.value, targetAngularVelocity, e.angularGait.acceleration * math.sign(targetAngularVelocity - e.angularVelocity.value), dt)
		end
	end
end

return walking
