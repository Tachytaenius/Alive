local concord = require("lib.concord")
local vec2 = require("lib.mathsies").vec2
return concord.component("sprite", function(c, radius)
	c.radius = radius
end)
