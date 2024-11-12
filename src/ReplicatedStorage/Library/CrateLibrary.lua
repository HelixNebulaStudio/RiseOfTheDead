local RunService = game:GetService("RunService");

local CrateLibrary = {};
local library = {};
CrateLibrary.Library = library;

function CrateLibrary.Get(id)
	return library[id];
end

function CrateLibrary.New(data)
	if library[data.Id] ~= nil then error("CrateLibrary>>  Crate ID ("..data.Id..") already exist for ("..data.Name..").") end;
	library[data.Id] = data;

	if RunService:IsServer() then
		if data.Prefab == nil then
			data.Prefab = game.ServerStorage.PrefabStorage.Objects:FindFirstChild(data.PrefabName);
		end
		
		if data.Prefab == nil then
			data.Prefab = game.ReplicatedStorage.Prefabs.Items:FindFirstChild(data.PrefabName);
		end

		local modTools = require(game.ReplicatedStorage.Library.Tools);
		if data.Prefab == nil and modTools[data.Id] then
			data.Prefab = modTools[data.Id].Prefab;
		end
		
		if data.Prefab == nil then
			error("CrateLibrary>>  Crate ID ("..data.Id..") invalid crate prefab ("..data.PrefabName..").");
		end
	end
end

local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local moddedSelf = modModEngineService:GetModule(script.Name);
if moddedSelf then moddedSelf:Init(CrateLibrary); end

return CrateLibrary;