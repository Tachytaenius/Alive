local consts = require("consts")

function love.conf(t)
	t.window = nil
	t.identity = consts.loveIdentity
	t.version = consts.loveVersion
end
