local concord = require("lib.concord")
return concord.component("gait", function(c, maxSpeed, acceleration, standThreshold, staggerRange)
	c.maxSpeed = maxSpeed
	c.acceleration = acceleration
	c.standThreshold = standThreshold -- Below this speed threshold the entity will get back on its feet
	-- Between stand threshold and trip threshold would be the stagger range
	c.tripThreshold = standThreshold + staggerRange -- Above this threshold the entity will fall over
end)
