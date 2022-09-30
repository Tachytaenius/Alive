# Chunks

Chunks are loaded from file or generated when they are inside the (middle) loading radius, only ticked when within the (smaller) processing radius, and unloaded when they reach the (larger) unloading radius.

You can't iterate over the loaded chunks list for processing as it is not deterministically ordered.

## Fields

- `x`: (Not saved) Chunk x position in chunks, not tiles or pixels.
- `y`: (Not saved) Chunk y position in chunks.
- `toppingMesh`: (Not saved) The mesh used for the tile toppings.
- `superToppingMeshes`: (Not saved) An array of meshes used for tile super toppings.
- `tiles`: (Saved) The 2D array of tiles.
- `randomTickTime` (Saved) The allotted time for random ticks to operate in.
	Saves excess for cases where dt (`consts.fixedUpdateTickLength`) is not a multiple of `consts.randomTickInterval`.
- `time` (Saved) The amount of time the chunk has been loaded for.
