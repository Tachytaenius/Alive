local concord = require("lib.concord")
return concord.component("vision", function(c, maxViewDistance)
	c.maxViewDistance = maxViewDistance
end)
