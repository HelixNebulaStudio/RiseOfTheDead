local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local RunService = game:GetService("RunService");

--
local Template = {}
Template.__index = Template;

function Template.new(parallelNpc)
	local meta = {};
	meta.__index = meta;
	meta.ParallelNpc = parallelNpc;

	local self = {};
	
	setmetatable(meta, Template);
	setmetatable(self, meta);

	local prefab: Actor = self.ParallelNpc.Prefab;
	local humanoid: Humanoid = self.ParallelNpc.Humanoid;
	local rootPart: BasePart = self.ParallelNpc.RootPart;
	
	
	return self;
end

return Template;