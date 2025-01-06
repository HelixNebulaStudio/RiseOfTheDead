local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local CollectionService = game:GetService("CollectionService");

local DeadbodiesHandler = {};
DeadbodiesHandler.__index = DeadbodiesHandler;

--==

function DeadbodiesHandler:DespawnRequest(maxBodies: number?)
	local deadbodiesList = CollectionService:GetTagged("Deadbody");

	local newTick = tick();

	local groups = {};
	for a=1, #deadbodiesList do
		local name = deadbodiesList[a].Name;
		if groups[name] == nil then
			groups[name] = {};
		end

		local model = deadbodiesList[a];
		if model:GetAttribute("DeadbodyTick") == nil then continue end;
		if newTick-model:GetAttribute("DeadbodyTick") <= 2 then continue end;

		table.insert(groups[name], model);
	end

	for name, list in pairs(groups) do
		table.sort(list, function(model)
			return model:GetAttribute("DeadbodyTick") < model:GetAttribute("DeadbodyTick");
		end)
		while #list > (maxBodies or 64) do
			local prefab = table.remove(list, 1);
			
			if Debugger:IsParallel() then
				task.synchronize();
				prefab:Destroy();
				task.desynchronize();
			else
				prefab:Destroy();
				task.wait();
			end
		end
	end
end


return DeadbodiesHandler;