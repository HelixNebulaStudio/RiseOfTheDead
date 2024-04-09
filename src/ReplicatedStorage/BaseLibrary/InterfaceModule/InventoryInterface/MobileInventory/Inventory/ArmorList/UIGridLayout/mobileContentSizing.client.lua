local frame = script.Parent.Parent;
local parent = script.Parent;
parent:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() --not crash
	frame.Size = UDim2.new(1, -10, 0, parent.AbsoluteContentSize.Y);
end)