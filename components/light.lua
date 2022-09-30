local concord = require("lib.concord")
return concord.component("light", function(c, r, g, b, radius)
	c.r = r
	c.g = g
	c.b = b
	c.radius = radius
end)
