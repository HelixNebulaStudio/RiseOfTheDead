local window = script.Parent.Parent;
local parent = script.Parent;
local mainframe = parent.Parent;

local function update()
	local mainframeSize = mainframe.AbsoluteSize;
	local memberSize = mainframe.Members.AbsoluteSize;
	local bannerSize = mainframe.Banner.AbsoluteSize;

	local newSize = mainframeSize.X-memberSize.X-bannerSize.X;
	parent.Position = UDim2.new(0, bannerSize.X, 0, 0);
	parent.Size = UDim2.new(0, newSize, 1, 0);
end

while true do
	if window.Visible then
		update();
		task.wait();
	else
		task.wait(1);
	end
end