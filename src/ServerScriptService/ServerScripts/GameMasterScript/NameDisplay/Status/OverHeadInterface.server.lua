local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local modLevelBadge = require(game.ReplicatedStorage.Library.LevelBadge);

local levelIconTag = script.Parent:WaitForChild("LevelIcon");
local levelLabel = levelIconTag:WaitForChild("LevelTag");

--== Script;
local function UpdateNameDisplay()
	local level = tonumber(levelLabel.Text);
	if level then
		modLevelBadge:Update(levelIconTag, level);
	end
end

levelLabel:GetPropertyChangedSignal("Text"):Connect(function()
	UpdateNameDisplay();
end)
repeat
	UpdateNameDisplay()
until not wait(10);