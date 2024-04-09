local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local RunService = game:GetService("RunService");

--
local Template = {}
Template.__index = Template;

function Template.new(parallelNpc)
	local self = {};
	
	setmetatable(self, Template);
	return self;
end

return Template;