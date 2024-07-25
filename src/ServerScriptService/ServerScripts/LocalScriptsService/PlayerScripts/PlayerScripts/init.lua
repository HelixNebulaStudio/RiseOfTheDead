local PlayerScripts = {};

local modEngineCore = require(game.ReplicatedStorage.EngineCore);

for _, s in pairs(script:GetChildren()) do
	if s.ClassName == "ModuleScript" then
		task.spawn(function()
			local init = require(s);
			init();
		end)
	end
end

-- local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
-- local moddedSelf = modModEngineService:GetModule(script.Name, game.ReplicatedStorage);
-- if moddedSelf then 
-- 	moddedSelf:Init();
-- end

return PlayerScripts;
