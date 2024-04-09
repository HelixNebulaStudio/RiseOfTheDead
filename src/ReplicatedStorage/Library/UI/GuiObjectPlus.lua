local Module = {};

local UserInputService = game:GetService("UserInputService");

function Module.IsMouseOver(guiObject)
	local Pos = UserInputService:GetMouseLocation();
	local X, Y = Pos.X, Pos.Y;
	local minV = guiObject.AbsolutePosition + Vector2.new(0, 36);
	local maxV = guiObject.AbsolutePosition + guiObject.AbsoluteSize + Vector2.new(0, 36);
	
	if X > minV.X and Y > minV.Y and X < maxV.X and Y < maxV.Y then
		return true;
	else 
		return false;
	end
end

return Module;