local path = (...):gsub("%.init$", "")

require(path .. ".monkeypatch")

local suit = require(path .. ".lib.suit")

local settings = require(path .. ".settings")
local config = require(path .. ".config")
local input = require(path .. ".input")
local assets = require(path .. ".assets")
local ui = require(path .. ".ui")

local takeScreenshot = require(path .. ".takeScreenshot")

local boilerplate = {}

boilerplate.settingsTypes = settings("meta")
boilerplate.assetsConstructors, boilerplate.assetsUtilities = assets("meta")

boilerplate.settings = settings
boilerplate.config = config
boilerplate.input = input
boilerplate.assets = assets
boilerplate.ui = ui
boilerplate.suit = suit

function boilerplate.remakeWindow()
	local width = config.canvasSystemWidth * settings.graphics.scale
	local height = config.canvasSystemHeight * settings.graphics.scale
	love.window.setMode(width, height, {
		vsync = settings.graphics.vsync,
		fullscreen = settings.graphics.fullscreen,
		borderless = settings.graphics.fullscreen and settings.graphics.borderlessFullscreen,
		display = settings.graphics.display
	})
	if config.windowTitle then
		love.window.setTitle(config.windowTitle)
	end
	if config.windowIconImageData then
		love.window.setIcon(config.windowIconImageData)
	end
end

local function paused()
	return ui.current and ui.current.causesPause
end

local function getMaxScale()
	local maxWidth, maxHeight = love.window.getDesktopDimensions(settings.graphics.display)
	local widthScaleLimit = math.floor(maxWidth / config.canvasSystemWidth)
	local heightScaleLimit = math.floor(maxHeight / config.canvasSystemHeight)
	return math.min(widthScaleLimit, heightScaleLimit)
end

function boilerplate.init(initConfig, arg)
	-- NOTE: initConfig is modified in some places
	-- TODO: Make a table for all the input options and verify their presence, perhaps even validate them
	
	love.graphics.setDefaultFilter(initConfig.defaultFilterMin or "nearest", initConfig.defaultFilterMag or initConfig.defaultFilterMin or "nearest", initConfig.defaultFilterAnisotropy)
	love.graphics.setLineStyle(initConfig.lineStyle or "rough")
	
	config.canvasSystemWidth, config.canvasSystemHeight = initConfig.canvasSystemWidth, initConfig.canvasSystemHeight
	
	-- Merge library-owned frame commands into frameCommands
	
	local frameCommands = initConfig.frameCommands
	
	frameCommands.toggleMouseGrab = frameCommands.toggleMouseGrab or "onRelease"
	frameCommands.takeScreenshot = frameCommands.takeScreenshot or "onRelease"
	frameCommands.toggleInfo = frameCommands.toggleInfo or "onRelease"
	frameCommands.previousDisplay = frameCommands.previousDisplay or "onRelease"
	frameCommands.nextDisplay = frameCommands.nextDisplay or "onRelease"
	frameCommands.scaleDown = frameCommands.scaleDown or "onRelease"
	frameCommands.scaleUp = frameCommands.scaleUp or "onRelease"
	frameCommands.toggleFullscreen = frameCommands.toggleFullscreen or "onRelease"
	
	frameCommands.uiModifier = frameCommands.uiModifier or "whileDown"
	
	-- Merge library-owned settings layout into settingsUiLayout, with library-owned settings layout entries first
	
	local settingsUiLayout = {
		{title = "Graphics",
			{name = "Fullscreen", "graphics","fullscreen"},
			{name = "Interpolation", "graphics","interpolation"},
			{name = "Scale", "graphics","scale", getLimit = getMaxScale},
			{name = "Which Display", "graphics","display", getLimit = love.window.getDisplayCount},
			{name = "VSync", "graphics","vsync"},
			{name = "Max Ticks per Frame", "graphics","maxTicksPerFrame", getLimit = function() return 8 end},
			{name = "Show Performance", "graphics","showPerformance"}
		},
		
		{title = "Mouse",
			{name = "Divide by Scale", "mouse","divideByScale"},
			{name = "X Sensitivity", "mouse","xSensitivity",
				getLowLimit = function() return 0.1 end,
				getLimit = function() return 2 end
			},
			{name = "Y Sensitivity", "mouse","ySensitivity",
				getLowLimit = function() return 0.1 end,
				getLimit = function() return 2 end
			},
			{name = "Cursor Colour", "mouse","cursorColour"}
		},
		
		{title = "Controls",
			{name = "Use Scancodes for Keys", "useScancodesForCommands"},
			{name = "Frame Commands", "frameCommands"},
			{named = "Fixed Commands", "fixedCommands"}
		}
	}
	
	for _, category in ipairs(initConfig.settingsUiLayout) do
		local libraryCategory
		for _, libraryCategory_ in ipairs(settingsUiLayout) do
			if category.title == libraryCategory_.title then
				libraryCategory = libraryCategory_
				break
			end
		end
		if not libraryCategory then
			libraryCategory = {title = category.title}
			settingsUiLayout[#settingsUiLayout + 1] = libraryCategory
		end
		for _, item in ipairs(category) do
			libraryCategory[#libraryCategory + 1] = item
		end
	end
	
	initConfig.settingsUiLayout = settingsUiLayout
	
	-- Merge library-owned settings into settingsTemplate
	
	local settingsTypes = boilerplate.settingsTypes
	local settingsTemplate = initConfig.settingsTemplate
	
	settingsTemplate.graphics = settingsTemplate.graphics or {}
	settingsTemplate.graphics.fullscreen = settingsTemplate.graphics.fullscreen or settingsTypes.boolean(false)
	settingsTemplate.graphics.interpolation = settingsTemplate.graphics.interpolation or settingsTypes.boolean(true)
	settingsTemplate.graphics.scale = settingsTemplate.graphics.scale or settingsTypes.natural(2)
	settingsTemplate.graphics.display = settingsTemplate.graphics.display or settingsTypes.natural(1)
	settingsTemplate.graphics.maxTicksPerFrame = settingsTemplate.graphics.maxTicksPerFrame or settingsTypes.natural(4)
	settingsTemplate.graphics.vsync = settingsTemplate.graphics.vsync or settingsTypes.boolean(true)
	settingsTemplate.graphics.showPerformance = settingsTemplate.graphics.showPerformance or settingsTypes.boolean(false)
	
	settingsTemplate.mouse = settingsTemplate.mouse or {}
	settingsTemplate.mouse.divideByScale = settingsTypes.boolean(true)
	settingsTemplate.mouse.xSensitivity = settingsTypes.number(1)
	settingsTemplate.mouse.ySensitivity = settingsTypes.number(1)
	settingsTemplate.mouse.cursorColour = settingsTypes.rgba(1, 1, 1, 1)
	
	settingsTemplate.useScancodesForCommands = settingsTemplate.useScancodesForCommands or settingsTypes.boolean(true)
	
	settingsTemplate.frameCommands = settingsTemplate.frameCommands or settingsTypes.commands("frame", {})
	local frameCommandsSettingDefaults = settingsTemplate.frameCommands(nil) -- HACK: Get defaults by calling with settingsTemplate.frameCommands with nil
	for commandName, inputType in pairs({
		toggleMouseGrab = "f1",
		takeScreenshot = "f2",
		toggleInfo = "f3",
		
		previousDisplay = "f7",
		nextDisplay = "f8",
		scaleDown = "f9",
		scaleUp = "f10",
		toggleFullscreen = "f11",
		
		uiModifier = "lalt"
	}) do
		frameCommandsSettingDefaults[commandName] = frameCommandsSettingDefaults[commandName] or inputType
	end
	
	assets("configure", initConfig.assets)
	settings("configure", initConfig.settingsUiLayout, initConfig.settingsTemplate)
	
	config.frameCommands = initConfig.frameCommands
	config.fixedCommands = initConfig.fixedCommands
	
	ui.configure(initConfig.uiNames, initConfig.uiNamePathPrefix)
	
	config.suppressQuitWithDoubleQuitEvent = initConfig.suppressQuitWithDoubleQuitEvent
	config.scrollSpeed = initConfig.scrollSpeed or 20
	config.uiPad = initConfig.uiPad or 4
	config.uiButtonPad = initConfig.uiButtonPad or 2
	config.pauseInputType = initConfig.pauseInputType or "released"
	config.windowTitle = initConfig.windowTitle
	config.windowIconImageData = initConfig.windowIconImageData
	
	local pausePressed, pauseReleased
	
	function love.run()
		love.load(love.arg.parseGameArguments(arg), arg)
		local lag = initConfig.fixedUpdateTickLength
		local updatesSinceLastDraw, lastLerp = 0, 1
		local performance
		local previousFramePaused
		love.timer.step()
		
		return function()
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do -- Events
				if name == "quit" then
					if not love.quit() then
						return a or 0
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
			
			do -- Update
				local delta = love.timer.step()
				lag = math.min(lag + delta, initConfig.fixedUpdateTickLength * settings.graphics.maxTicksPerFrame)
				local frames = math.floor(lag / initConfig.fixedUpdateTickLength)
				lag = lag % initConfig.fixedUpdateTickLength
				if not paused() then
					local start = love.timer.getTime()
					for _=1, frames do
						updatesSinceLastDraw = updatesSinceLastDraw + 1
						love.fixedUpdate(initConfig.fixedUpdateTickLength)
					end
					if frames ~= 0 then
						performance = (love.timer.getTime() - start) / (frames * initConfig.fixedUpdateTickLength)
					end
				else
					performance = nil
				end
				previousFramePaused = ui.current and ui.current.causesPause
				love.update(delta, performance)
			end
			
			if love.graphics.isActive() then -- Rendering
				love.graphics.origin()
				love.graphics.clear(love.graphics.getBackgroundColor())
				
				local lerp = lag / initConfig.fixedUpdateTickLength
				local deltaDrawTime = ((lerp + updatesSinceLastDraw) - lastLerp) * initConfig.fixedUpdateTickLength
				love.draw(lerp, deltaDrawTime, performance)
				updatesSinceLastDraw, lastLerp = 0, lerp
				
				love.graphics.present()
			end
			
			love.timer.sleep(0.001)
		end
	end
	
	function love.load(arg, unfilteredArg)
		input.frameUpdates = {{}, {}}
		input.fixedUpdates = {{}, {}}
		input.recording = false -- TODO
		input.replaying = false -- TODO
		settings("load")
		settings("apply")
		settings("save")
		assets("load")
		love.graphics.setFont(assets.ui.font.value)
		boilerplate.gameCanvas = love.graphics.newCanvas(config.canvasSystemWidth, config.canvasSystemHeight)
		boilerplate.hudCanvas = love.graphics.newCanvas(config.canvasSystemWidth, config.canvasSystemHeight)
		boilerplate.infoCanvas = love.graphics.newCanvas(config.canvasSystemWidth, config.canvasSystemHeight)
		boilerplate.outputCanvas = love.graphics.newCanvas(config.canvasSystemWidth, config.canvasSystemHeight)
		boilerplate.outlineShader = love.graphics.newShader(path:gsub("%.", "/") .. "/shaders/outline.glsl")
		boilerplate.fixedMouseDx, boilerplate.fixedMouseDy = 0, 0 -- Prevent first frame nil, nil
		if boilerplate.load then
			boilerplate.load(arg, unfilteredArg)
		end
	end
	
	function love.update(dt)
		if config.pauseInputType == "pressed" and pausePressed or config.pauseInputType == "released" and pauseReleased then
			if ui.current then
				if not ui.current.ignorePausePress then
					ui.destroy()
				end
			else
				ui.construct("plainPause")
			end
		end
		
		if input.checkFrameUpdateCommand("toggleMouseGrab") then
			love.mouse.setRelativeMode(not love.mouse.getRelativeMode())
		end
		
		if input.checkFrameUpdateCommand("takeScreenshot") then
			-- If uiModifier is held then takeScreenshot will exclude HUD et cetera.
			if input.checkFrameUpdateCommand("uiModifier") then
				takeScreenshot(boilerplate.gameCanvas, "game")
			else
				takeScreenshot(boilerplate.outputCanvas, "game & HUD")
			end
		end
		
		if not ui.current or ui.current.type ~= "settings" then
			if input.checkFrameUpdateCommand("toggleInfo") then
				settings.graphics.showPerformance = not settings.graphics.showPerformance
				settings("save")
			end
			
			if input.checkFrameUpdateCommand("previousDisplay") and love.window.getDisplayCount() > 1 then
				settings.graphics.display = (settings.graphics.display - 2) % love.window.getDisplayCount() + 1
				settings("apply") -- TODO: Test thingy... y'know, "press enter to save or wait 5 seconds to revert"
				settings("save")
			end
			
			if input.checkFrameUpdateCommand("nextDisplay") and love.window.getDisplayCount() > 1 then
				settings.graphics.display = (settings.graphics.display) % love.window.getDisplayCount() + 1
				settings("apply")
				settings("save")
			end
			
			if input.checkFrameUpdateCommand("scaleDown") and settings.graphics.scale > 1 then
				settings.graphics.scale = settings.graphics.scale - 1
				settings("apply")
				settings("save")
			end
			
			if input.checkFrameUpdateCommand("scaleUp") then
				settings.graphics.scale = math.min(getMaxScale(), settings.graphics.scale + 1)
				settings("apply")
				settings("save")
			end
			
			if input.checkFrameUpdateCommand("toggleFullscreen") then
				settings.graphics.fullscreen = not settings.graphics.fullscreen
				settings("apply")
				settings("save")
			end
		end
		
		if ui.current then
			ui.update()
		end
		
		if boilerplate.update then
			boilerplate.update(dt)
		end
		
		input.stepFrameUpdate()
		pausePressed, pauseReleased = false, false
	end
	
	function love.fixedUpdate(dt)
		if boilerplate.fixedUpdate then
			boilerplate.fixedUpdate(dt)
		end
		
		boilerplate.fixedMouseDx, boilerplate.fixedMouseDy = 0, 0
		if not paused() then
			input.stepFixedUpdate()
		end
	end
	
	function love.draw(lerp, dt, performance)
		if settings.graphics.showPerformance then
			love.graphics.setCanvas(boilerplate.infoCanvas)
			love.graphics.clear()
			love.graphics.print(
				"FPS: " .. love.timer.getFPS() .. "\n" ..
				-- "Garbage: " .. collectgarbage("count") * 1024 -- counts all memory for some reason
				"Tick time: " .. (performance and math.floor(performance * 100 + 0.5) .. "%" or "N/A"),
			1, 1)
		end
		
		if boilerplate.draw and not paused() then
			-- Draw to input canvas
			boilerplate.draw(settings.graphics.interpolation and lerp or 1, dt, performance)
		end
		
		love.graphics.setCanvas(boilerplate.outputCanvas)
		love.graphics.clear(0, 0, 0, 1)
		
		if ui.current then
			love.graphics.setColor(initConfig.uiTint or {1, 1, 1})
		end
		love.graphics.draw(boilerplate.gameCanvas)
		love.graphics.setColor(1, 1, 1)
		
		if ui.current then
			suit.draw()
			if ui.current.draw then
				ui.current.draw() -- stuff SUIT can't do: rectangles, lines, etc
			end
			love.graphics.setColor(settings.mouse.cursorColour)
			love.graphics.draw(assets.ui.cursor.value, math.floor(ui.current.mouseX), math.floor(ui.current.mouseY))
			love.graphics.setColor(1, 1, 1)
		else
			love.graphics.draw(boilerplate.hudCanvas)
		end
		
		if settings.graphics.showPerformance then
			love.graphics.setShader(boilerplate.outlineShader)
			boilerplate.outlineShader:send("windowSize", {config.canvasSystemWidth, config.canvasSystemHeight})
			love.graphics.draw(boilerplate.infoCanvas, 1, 1)
			love.graphics.setShader()
		end
		
		love.graphics.setCanvas()
		
		love.graphics.draw(boilerplate.outputCanvas,
			love.graphics.getWidth() / 2 - (config.canvasSystemWidth * settings.graphics.scale) / 2, -- topLeftX == centreX - width / 2
			love.graphics.getHeight() / 2 - (config.canvasSystemHeight * settings.graphics.scale) / 2,
			0, settings.graphics.scale
		)
	end
	
	function love.quit()
		if not (boilerplate.quit and boilerplate.quit()) then
			if boilerplate.getUnsaved and boilerplate.getUnsaved() then
				if ui.current and ui.current.type == "quitConfirmation" then
					return config.suppressQuitWithDoubleQuitEvent and not boilerplate.forceQuit
				else
					ui.construct("quitConfirmation")
					return true
				end
			end
		end
	end
	
	function love.mousemoved(x, y, dx, dy)
		if love.window.hasFocus() and love.window.hasMouseFocus() and love.mouse.getRelativeMode() then
			if ui.current then
				ui.mouse(dx, dy)
			else
				boilerplate.fixedMouseDx = boilerplate.fixedMouseDx + dx
				boilerplate.fixedMouseDy = boilerplate.fixedMouseDy + dy
			end
		end
	end
	
	function love.mousepressed(x, y, button, isTouch)
		if not love.mouse.getRelativeMode() then
			love.mouse.setRelativeMode(true)
			boilerplate.disableMouseButtonUntilReleased = button
		end
	end
	
	function love.mousereleased(x, y, button, isTouch)
		boilerplate.disableMouseButtonUntilReleased = nil
	end
	
	function love.wheelmoved(x, y)
		if ui.current then
			ui.current.scrollAmountY = y -- Unset in ui.update
		end
	end
	
	function love.keypressed(key, scancode)
		if key == "escape" then
			pausePressed = true
		end
	end
	
	function love.keyreleased(key, scancode)
		if key == "escape" then
			pauseReleased = true
		end
	end
end

return boilerplate
