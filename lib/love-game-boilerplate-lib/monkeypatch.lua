local path = (...):gsub("%.[^%.]+$", "")

do -- Stop suit from updating mouse by itself
	local suitCore = require(path .. ".lib.suit.core")
	
	-- First we hack NONE out of suit.enterFrame
	local dummy = {
		active = true,
		updateMouse = function() end,
		grabKeyboardFocus = function() end
	}
	suitCore.enterFrame(dummy)
	local NONE = dummy.active
	
	-- Then we replace it with our own
	function suitCore:enterFrame()
		if not self.mouse_button_down then
			self.active = nil
		elseif self.active == nil then
			self.active = NONE
		end

		self.hovered_last, self.hovered = self.hovered, nil
		-- self:updateMouse(love.mouse.getX(), love.mouse.getY(), love.mouse.isDown(1)) -- This is the line that's changed
		self.key_down, self.textchar = nil, ""
		self:grabKeyboardFocus(NONE)
		self.hit = nil
	end
end
