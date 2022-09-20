local concord = require("lib.concord")

local movement = concord.system({translatees = {"position", "velocity"}})

function movement:fixedUpdate(dt)
	for _, e in ipairs(self.translatees) do
		e.position.val = e.position.val + e.velocity.val * dt
	end
end

return movement
