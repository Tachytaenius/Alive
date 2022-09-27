# Chunks

Chunks are loaded from file or generated when they are inside the smaller loading radius, only ticked when within that radius, and unloaded when they reach the larger unloading radius.

## Fields

- `x`: Chunk x position in chunks, not tiles or pixels.
- `y`: Chunk y position in chunks.
- `toppingMesh`: The mesh used for the tile toppings.
- `superToppingMesh`: An array of meshes used for tile super toppings.
- `tiles`: The 2D array of tiles.
