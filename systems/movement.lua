local concord = require("lib.concord")

local movement = concord.system({translatees = {"position", "velocity"}})

function movement:fixedUpdate(dt)
	for _, e in ipairs(self.translatees) do
		e.position.value = e.position.value + e.velocity.value * dt
	end
end

return movement
