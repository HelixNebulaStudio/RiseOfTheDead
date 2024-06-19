local Module = {};

local GuiService = game:GetService("GuiService");
local UserInputService = game:GetService("UserInputService");

function Module.IsMouseOver(guiObject)
	local Pos = UserInputService:GetMouseLocation();
	local X, Y = Pos.X, Pos.Y;
	local minV = guiObject.AbsolutePosition + Vector2.new(0, GuiService.TopbarInset.Height);
	local maxV = guiObject.AbsolutePosition + guiObject.AbsoluteSize + Vector2.new(0, GuiService.TopbarInset.Height);
	
	if X > minV.X and Y > minV.Y and X < maxV.X and Y < maxV.Y then
		return true;
	else 
		return false;
	end
end

return Module;