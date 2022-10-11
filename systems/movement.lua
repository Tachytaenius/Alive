local concord = require("lib.concord")

local movement = concord.system({
	translatees = {"position", "velocity"},
	rotatees = {"angle", "angularVelocity"}
})

function movement:fixedUpdate(dt)
	for _, e in ipairs(self.translatees) do
		e.position.value = e.position.value + e.velocity.value * dt
	end

	for _, e in ipairs(self.rotatees) do
		e.angle.value = (e.angle.value + e.angularVelocity.value * dt) % math.tau
	end
end

return movement
