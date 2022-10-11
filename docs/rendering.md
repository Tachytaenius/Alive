# Rendering

## On Fixed Update

On fixed update, the chunk mesh vertices associated with changed tiles are modified.

## On Draw

There are two types of canvas, game canvas-sized canvases and pre crush canvas-sized canvases.
The whole game world is drawn to the pre crush canvases and then crushed down so that further-away things are smaller to fit more in the screen.

The pre crush canvases are:
- Albedo: Stores the colour being drawn.
- Light filter: Stores the light filter colour being drawn-- responsible for shadows and the world being coloured through coloured glass.
- Lighting: Cleared to the ambient light colour, the influences of lights are drawn to this canvas.

The game canvas-sized canvases are:
- Boilerplate game canvas: Final output target from rendering system.
- Crushed light filter canvas: A crushed version of the light filter canvas, used to optimise a large light filter operation centred on the player that would otherwise run on many pixels in the pre crush canvas size.

### Player Check

The first entity with components `player`, `position`, and `vision` is selected as the camera.
There is only supposed to be one `player`-having entity in a world.
The output canvas is black if no such player is present.

### Transformation

When drawing the world to the pre crush canvases, the drawing transformation matrix is set to be relative to the centre of the pre crush canvas size and relative to the player's position and orientation.

### Chunks

Chunk toppings meshes and super topping meshes are drawn to the pre crush canvases.
Chunks behind the player except ones within the player's sensing circle are not drawn.
Greater-than-180-degrees FOV won't work with the dividing-plane-in-half chunk draw culling optimisation.

### Entities

Entities are drawn on top of chunks.
They are drawn sorted into two groups (with only one `table.sort` call, though): inside the topping layer (in a ditch) and above the topping layer, with lower entities drawn first (underneath), then sorted by distance with more distant entities drawn first (underneath).

### Lights

Then the game switches to the lighting phase.
It clears the lighting canvas to the ambient light level and sets the blend mode to additive.
Light influences are then drawn to the lighting canvas using the light info canvas to cast shadows or filter the colour of light.

Then the lights are applied by multiplying (blend mode set) the albedo canvas into the lighting canvas, setting the blend mode back to default.

### Crushing

Next the lighting canvas, which now contains a lit-up world, along with the light info canvas, is crushed so that more of the pre crush-sized lighting canvas can fit on the screen.

### View Light Filtering

Finally, the player's view is light-filtered, but on the crushed canvases, since there are so many pixels to filter.
This would not work if the player's view "light" origin was not the same as the centre of the crush effect.
