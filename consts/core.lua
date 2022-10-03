local core = {}

core.version = 1
core.fixedUpdateTickLength = 1 / 24
core.seedBytes = 2 -- TEMP: When love 12 comes out, we can use 4. This is for love.math.noise reasons
core.maxWorldSeed = math.ldexp(1, core.seedBytes * 8)-1
core.windowTitle = "Alive"
core.loveVersion = "11.4"
core.loveIdentity = "alive"
core.firstSubWorldId = 1 -- Not 0 because 0 isn't counted as part of an array and subWorlds are processed as a sorted array

return core
