local concord = require("lib.concord")

local walking = concord.system({walkers = {"will", "velocity"}})

function walking:fixedUpdate(dt)
	for _, e in ipairs(self.walkers) do
		if e.will.movement then
			e.velocity.val = e.velocity.val + e.will.accel * dt
		end
	end
end

return walking
