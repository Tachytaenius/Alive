local concord = require("lib.concord")
local vec2 = require("lib.mathsies").vec2
return concord.component("position", function(c, x, y)
	c.value = vec2(x, y)
end)
