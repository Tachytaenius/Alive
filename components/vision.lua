local concord = require("lib.concord")
return concord.component("vision", function(c, renderDistance)
	c.renderDistance = renderDistance
end)
