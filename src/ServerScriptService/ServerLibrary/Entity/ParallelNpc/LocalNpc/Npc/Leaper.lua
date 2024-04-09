local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

--
local Leaper = {}
Leaper.__index = Leaper;

function Leaper.new(localNpc)
	local meta = {};
	meta.__index = meta;
	meta.LocalNpc = localNpc;

	local self = {};
	
	setmetatable(meta, Leaper);
	setmetatable(self, meta);

	local prefab: Actor = self.LocalNpc.Prefab;
	local humanoid: Humanoid = self.LocalNpc.Humanoid;
	local rootPart: BasePart = self.LocalNpc.RootPart;
	
	return self;
end

return Leaper;