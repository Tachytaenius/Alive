local concord = require("lib.concord")
return concord.component("angularVelocity", function(c, value)
	c.value = value or 0
end)
