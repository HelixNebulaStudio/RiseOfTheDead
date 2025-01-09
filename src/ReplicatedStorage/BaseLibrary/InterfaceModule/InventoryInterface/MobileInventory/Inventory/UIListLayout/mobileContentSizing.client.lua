local frame = script.Parent.Parent;
local parent = script.Parent;
parent:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() --not crash
	frame.CanvasSize = UDim2.new(0, 0, 0, parent.AbsoluteContentSize.Y);
end)