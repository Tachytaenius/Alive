local consts = require("consts")
local serialisation = require("serialisation")

local chunks = {}

function chunks:removeChunkFromGrid(chunk)
	assert(self.chunks[chunk.x][chunk.y], "No chunk to remove from grid at " .. chunk.x .. ", " .. chunk.y)
	self.chunks[chunk.x][chunk.y] = nil
	local hasValue = false
	for _ in pairs(self.chunks[chunk.x]) do
		hasValue = true
		break
	end
	if not hasValue then
		self.chunks[chunk.x] = nil
	end
end

function chunks:addChunkToGrid(chunk)
	self.chunks[chunk.x] = self.chunks[chunk.x] or {}
	assert(not self.chunks[chunk.x][chunk.y], "Can't add to grid, chunk already exists at " .. chunk.x .. ", " .. chunk.y)
	self.chunks[chunk.x][chunk.y] = chunk
end

function chunks:getChunk(x, y)
	if self.chunks[x] then
		return self.chunks[x][y]
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
	assert(not (self.chunks[x] and self.chunks[x][y]), "Can't request chunk, chunk already exists at " .. x .. ", " .. y)
	self:registerChunkRequest(x, y)
	self.requestChannel:push({x = x, y = y})
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
	self:addChunkToGrid(chunk)
	self:makeChunkMeshes(chunk)
	self.loadedChunks:add(chunk)
end

function chunks:unloadChunk(chunk)
	self:removeChunkFromGrid(chunk)
	self.loadedChunks:remove(chunk)
	local info = love.filesystem.getInfo("chunks/")
	if not info then
		love.filesystem.createDirectory("chunks/")
	elseif info.type ~= "directory" then
		error("There is a non-folder item at chunks/")
	end
	local path = "chunks/" .. chunk.x .. "," .. chunk.y .. ".bin"
	local data = serialisation.serialiseChunk(chunk)
	local success, errorMessage = love.filesystem.write(path, data)
	if not success then
		error("Could not create file for chunk at " .. chunk.x .. ", " .. chunk.y .. ": " .. errorMessage)
	end
end

return chunks
