local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local library = shared.require(game.ReplicatedStorage.Library.UsableItems);
--==

function library.onRequire()
	local function new(obj)
		if obj.ClassName ~= "ModuleScript" or obj.Name == "UsablePreset" then return end;
		local data = shared.require(obj);
		data.Id = obj.Name;
		data.Module = obj;
		library:Add(data);

		if RunService:IsServer() and data.ServerInit then
			task.spawn(data.ServerInit, data);
		end
		if RunService:IsClient() and data.ClientInit then
			task.spawn(data.ClientInit, data);
		end
	end

	for _, obj in pairs(script:GetChildren()) do
		new(obj);
	end
	script.ChildAdded:Connect(function(obj)
		new(obj);
	end)
	
	local function add(data)
		local usableObj = shared.require(script.Generics:FindFirstChild(data.Type));
		usableObj.__index = usableObj;
		
		local self = data;
		setmetatable(self, usableObj);
		
		library:Add(self);
	end
	
	--== Skin Permanent
	local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
	local skinPermList = modItemsLibrary.Library:ListByMatchFunc(function(itemLib)
		return modItemsLibrary:HasTag(itemLib.Id, "Skin Perm");
	end)

	for a=1, #skinPermList do
		local itemLib = skinPermList[a];
		
		add{
			Id=itemLib.Id;
			Type="SkinPerm";
		};
	end
	
	--== Unlock Packs
	local unlockPackList = modItemsLibrary.Library:ListByMatchFunc(function(itemLib)
		return itemLib.UnlockPack ~= nil;
	end)
	for a=1, #unlockPackList do
		local itemLib = unlockPackList[a];
		
		add{
			Id=itemLib.Id;
			PackType = itemLib.UnlockPack.Type;
			PackId = itemLib.UnlockPack.Id;
			Type="UnlockPack";
		};
	end

	--== Unlock Papers
	local modSafehomesLibrary = shared.require(game.ReplicatedStorage.Library.SafehomesLibrary);
	local papersList = modSafehomesLibrary:ListByMatchFunc(function(itemLib)
		return itemLib.UnlockPapers == true;
	end)

	for a=1, #papersList do
		local safehomeLib = papersList[a];

		add{
			Id=`{safehomeLib.Id}unlockpapers`;
			Type="UnlockPapers";
		};
	end
end

return library;