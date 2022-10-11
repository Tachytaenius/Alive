local concord = require("lib.concord")
local vec2 = require("lib.mathsies").vec2

local consts = require("consts")

local flying = concord.system({
	flyers = {"flying", "velocity"},
	walkers = {"grounded", "gait", "velocity"}
})

function flying:fixedUpdate(dt)
	for _, e in ipairs(self.flyers) do
		local speed = #e.velocity.value
		local speedReduction = e.flyingRecoveryRate and e.flyingRecoveryRate.value or consts.defaultFlyingRecoveryRate
		speed = math.max(0, speed - speedReduction * dt)
		if e.gait then
			if speed <= e.gait.standThreshold then
				if not e.levitates then
					e:remove("flying")
					e:give("grounded")
				end
			end
		else
			if speed == 0 then
				if not e.levitates then
					e:remove("flying")
					e:give("grounded")
				end
			end
		end
		if #e.velocity.value > 0 then
			e.velocity.value = vec2.normalise(e.velocity.value) * speed
		end
	end

	for _, e in ipairs(self.walkers) do
		-- Have entities moving faster than their tripThreshold trip up
		if #e.velocity.value > e.gait.tripThreshold then
			e:remove("grounded")
			e:give("flying")
		end
	end
end

return flying

