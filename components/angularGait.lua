local concord = require("lib.concord")
return concord.component("angularGait", function(c, maxSpeed, acceleration)
	c.maxSpeed = maxSpeed
	c.acceleration = acceleration
end)
