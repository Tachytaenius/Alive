local concord = require("lib.concord")
return concord.component("light", function(c, red, green, blue, radius)
	c.red = red
	c.green = green
	c.blue = blue
	c.radius = radius
end)
