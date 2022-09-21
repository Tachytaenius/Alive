local concord = require("lib.concord")
return concord.component("flyingRecoveryRate", function(c, rate)
	c.value = rate -- How much speed to subtract per second when flying
end)
