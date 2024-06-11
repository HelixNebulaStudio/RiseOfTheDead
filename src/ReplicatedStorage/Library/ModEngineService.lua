local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local ModEngineService = {};
ModEngineService.__index = ModEngineService;

local RunService = game:GetService("RunService");

ModEngineService.ModLibrary = Debugger:YieldDir(game.ReplicatedStorage, "ModLibrary", 5);
ModEngineService.BaseLibrary = Debugger:YieldDir(game.ReplicatedStorage, "BaseLibrary", 5);


if RunService:IsServer() then
	ModEngineService.ModServerLibrary = game.ServerScriptService:FindFirstChild("ModServerLibrary");
	ModEngineService.BaseServerLibrary = game.ServerScriptService:FindFirstChild("BaseServerLibrary");
	
else
	for _, obj in pairs(game.ReplicatedStorage:GetChildren()) do game.ReplicatedStorage:WaitForChild(obj.Name) end;
	
end

if ModEngineService.ModLibrary then
	for _, obj in pairs(ModEngineService.ModLibrary:GetChildren()) do
		ModEngineService.ModLibrary:WaitForChild(obj.Name)
	end;
end
if ModEngineService.BaseLibrary then
	for _, obj in pairs(ModEngineService.BaseLibrary:GetChildren()) do
		ModEngineService.BaseLibrary:WaitForChild(obj.Name)
	end;
end

--== Script;
function ModEngineService:GetModule(name, parent, timeOut)
	if ModEngineService.ModLibrary then
		local moduleScript;
		if parent then
			moduleScript = Debugger:YieldDir(parent, name, timeOut);
			
			return require(parent[name]);
		end
		
		moduleScript = Debugger:YieldDir(ModEngineService.ModLibrary, name, timeOut);
		
		if moduleScript then
			return require(moduleScript);
		else
			return self:GetBaseModule(name, timeOut); -- idk why it was disabled
		end
	else
		return self:GetBaseModule(name, timeOut);
	end
end

function ModEngineService:GetBaseModule(name, timeOut)
	if ModEngineService.BaseLibrary then
		local moduleScript = Debugger:YieldDir(ModEngineService.BaseLibrary, name, timeOut);
		
		if moduleScript then
			return require(moduleScript);
		end
	end

	return;
end

--- Server

function ModEngineService:GetServerModule(name, parent, timeOut)
	if not RunService:IsServer() then return end;
	
	if ModEngineService.ModServerLibrary then
		local moduleScript = Debugger:YieldDir(ModEngineService.ModServerLibrary, name, timeOut);
		if moduleScript then
			return require(moduleScript);
		end

	else
		return self:GetBaseServerModule(name);

	end

	return;
end

function ModEngineService:GetBaseServerModule(name, parent, timeOut)
	if ModEngineService.BaseServerLibrary then
		local moduleScript = Debugger:YieldDir(ModEngineService.BaseServerLibrary, name, timeOut);
		if moduleScript then
			return require(moduleScript);
		end
	end

	return;
end

return ModEngineService;