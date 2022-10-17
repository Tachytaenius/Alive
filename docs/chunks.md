# Chunks

Chunks are requested to be loaded from file or generated on a thread when they are inside the (middle) loading radius, only ticked when within the (smaller) processing radius, and unloaded when they reach the (larger) unloading radius.
The whole game waits for all requested chunks to load when ticking if any requested chunks enter the force loading radius (between processing and loading radii).

You can't iterate over the loaded chunks list for processing as it is not deterministically ordered.

## Fields

- `x`: (Not saved) Chunk x position in chunks, not tiles or pixels.
- `y`: (Not saved) Chunk y position in chunks.
- `tiles`: (Saved) The 2D array of tiles.
- `randomTickTime` (Saved) The allotted time for random ticks to operate in.
	Saves excess for cases where dt (`consts.fixedUpdateTickLength`) is not a multiple of `consts.randomTickInterval`.
- `time` (Saved) The amount of time the chunk has been loaded for.
