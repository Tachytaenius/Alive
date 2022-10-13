local consts = require("consts")
local util = require("util")

local chunks = {}

function chunks:getChunkIterationStartEnd(player, radius)
	local x1 = math.floor((player.position.value.x - radius) / (consts.chunkWidth * consts.tileWidth))
	local x2 = math.ceil((player.position.value.x + radius) / (consts.chunkWidth * consts.tileWidth))
	local y1 = math.floor((player.position.value.y - radius) / (consts.chunkHeight * consts.tileHeight))
	local y2 = math.ceil((player.position.value.y + radius) / (consts.chunkHeight * consts.tileHeight))
	return x1, x2, y1, y2
end

function chunks:chunkPositionIsInRadius(x, y, player, radius)
	return util.collision.circleAabb(
		player.position.value.x, player.position.value.y, radius,
		x * consts.chunkWidth * consts.tileWidth, y * consts.chunkHeight * consts.tileHeight, consts.chunkWidth * consts.tileWidth, consts.chunkHeight * consts.tileHeight
	)
end

function chunks:removeChunkFromLoadedChunksGrid(chunk)
	assert(self.loadedChunksGrid[chunk.x][chunk.y], "No chunk to remove from grid at " .. chunk.x .. ", " .. chunk.y)
	self.loadedChunksGrid[chunk.x][chunk.y] = nil
	local hasValue = false
	for _ in pairs(self.loadedChunksGrid[chunk.x]) do
		hasValue = true
		break
	end
	if not hasValue then
		self.loadedChunksGrid[chunk.x] = nil
	end
end

function chunks:addChunkToLoadedChunksGrid(chunk)
	self.loadedChunksGrid[chunk.x] = self.loadedChunksGrid[chunk.x] or {}
	assert(not self.loadedChunksGrid[chunk.x][chunk.y], "Can't add to grid, chunk already exists at " .. chunk.x .. ", " .. chunk.y)
	self.loadedChunksGrid[chunk.x][chunk.y] = chunk
end

function chunks:getLoadedChunk(x, y)
	if self.loadedChunksGrid[x] then
		return self.loadedChunksGrid[x][y]
	end
end

function chunks:unregisterChunkRequest(x, y)
	assert(self.chunkRequests[x][y], "No chunk request to remove from chunk request grid at " .. x .. ", " .. y)
	self.chunkRequests[x][y] = nil
	local hasValue = false
	for _ in pairs(self.chunkRequests[x]) do
		hasValue = true
		break
	end
	if not hasValue then
		self.chunkRequests[x] = nil
	end
end

function chunks:registerChunkRequest(x, y)
	self.chunkRequests[x] = self.chunkRequests[x] or {}
	assert(not self.chunkRequests[x][y], "Can't add to chunk request grid, chunk request already exists at " .. x .. ", " .. y)
	self.chunkRequests[x][y] = true
end

function chunks:getChunkRequest(x, y)
	if self.chunkRequests[x] then
		return self.chunkRequests[x][y]
	end
end

function chunks:requestChunk(x, y)
	assert(not (self.loadedChunksGrid[x] and self.loadedChunksGrid[x][y]), "Can't request chunk, chunk already exists at " .. x .. ", " .. y)
	self:registerChunkRequest(x, y)
	self.requestChannel:push({x = x, y = y})
	self.activeChunkRequests = self.activeChunkRequests + 1
end

function chunks:receiveChunk(chunk)
	local changedTiles = self:getWorld().rendering.changedTiles
	for x = 0, consts.chunkWidth - 1 do
		for y = 0, consts.chunkHeight - 1 do
			local tile = chunk.tiles[x][y]
			changedTiles[#changedTiles + 1] = tile
			tile.chunk = chunk
			self:updateTileRendering(tile)
		end
	end
	self:unregisterChunkRequest(chunk.x, chunk.y)
	self:addChunkToLoadedChunksGrid(chunk)
	self:makeChunkMeshes(chunk)
	self:checkEmptyMeshes(chunk)
	self.loadedChunksList:add(chunk)
	self.activeChunkRequests = self.activeChunkRequests - 1
	assert(self.activeChunkRequests >= 0, "Remaining chunk requests is negative")
end

function chunks:unloadChunk(chunk)
	self:removeChunkFromLoadedChunksGrid(chunk)
	self.loadedChunksList:remove(chunk)
	local info = love.filesystem.getInfo("current/chunks/")
	if not info then
		love.filesystem.createDirectory("current/chunks/")
	elseif info.type ~= "directory" then
		error("There is a non-folder item at current/chunks/")
	end
	local path = "current/chunks/" .. chunk.x .. "," .. chunk.y .. ".bin"
	local data = util.saveFiles.serialisation.serialiseChunk(chunk)
	local success, errorMessage = love.filesystem.write(path, data)
	if not success then
		error("Could not write file for chunk at " .. chunk.x .. ", " .. chunk.y .. ": " .. errorMessage)
	end
end

function chunks:checkEmptyMeshes(chunk)
	local toppingPresent, superToppingPresences = false, {}
	for x = 0, consts.chunkWidth - 1 do
		for y = 0, consts.chunkHeight - 1 do
			local tile = chunk.tiles[x][y]
			if tile.topping then
				toppingPresent = true
			end
			if tile.superTopping then
				if tile.superTopping.type == "wall" then
					superToppingPresences[1] = true
				else -- "subLayers"
					for i = 1, consts.maxSubLayers do
						superToppingPresences[i] = not not tile.superTopping.subLayers[i]
					end
				end
			end
		end
	end
	chunk.toppingPresent = toppingPresent
	chunk.superToppingPresences = superToppingPresences
end

return chunks
