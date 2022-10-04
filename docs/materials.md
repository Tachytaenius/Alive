# Materials

Part of the registry.

Fields:
- `colour`: An array of three 0-1 numbers corresponding to red, green, and blue, in sRGB.
- `grassDeadColour`: For grass super topping sub-layers, display colour is a lerp between this and `colour` using `grassHealth`.
	Also in sRGB.
- `lightFilterColour`: Like `colour`, but it's what this material contributes to the light filter canvas as a constituent-- if it is a wall.
	Also in sRGB.
	Defaults to black.
- `noiseSize`: Higher numbers mean bigger clouds when rendering tiles.
- `visualWeight`: How much to multiply into the weight of this material's impact on the apppearance of a tile. Defaults to 1.
- `noiseContrast`: The contrast of the noise texture.
- `noiseBrightness`: The brightness of the noise texture.
- `grassGrowthRate`: For grass, how much `grassAmount` is added to per second at full `grassHealth`.
- `grassDecayRate`: For grass, how much `grassAmount` loses per second at 0 `grassHealth`.
- `grassHealthIncreaseRate`: For grass, how much `grassHealth` is added to per second when grass health is increasing.
- `grassHealthDecreaseRate`: For grass, how much `grassHealth` loses per second when grass target health is lower than current health.
- `grassNoiseFullness1`: The `grassAmount` at and above which the texture fullness is 1. Defaults to 1.
- `grassTargetAmountAdd`: Amount to add to health to get target grass amount when doing growth/decay calculations.
	Target remains clamped between 0 and 1.
	Is not used when grass health is 0.
- `grassTargetHealthZero`: Under or at this threshold when calculated, the target health of grass will be set to 0.
	Defaults to 0.
