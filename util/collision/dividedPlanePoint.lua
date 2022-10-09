return function(lineStartX, lineStartY, lineEndX, lineEndY, pointX, pointY)
	return ((lineEndX - lineStartX) * (pointY - lineStartY) - (pointX - lineStartX) * (lineEndY - lineStartY)) > 0
end
