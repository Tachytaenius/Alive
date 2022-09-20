local concord = require("lib.concord")
local vec2 = require("lib.mathsies").vec2
return concord.component("velocity", function(c, x, y)
	c.val = vec2(x, y)
end)
