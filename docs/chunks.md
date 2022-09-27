# Chunks

Chunks are loaded from file or generated when they are inside the smaller loading radius, only ticked when within that radius, and unloaded when they reach the larger unloading radius.

## Fields

- `x`: (Not saved) Chunk x position in chunks, not tiles or pixels.
- `y`: (Not saved) Chunk y position in chunks.
- `toppingMesh`: (Not saved) The mesh used for the tile toppings.
- `superToppingMesh`: (Not saved) An array of meshes used for tile super toppings.
- `tiles`: (Saved, altered) The 2D array of tiles.
