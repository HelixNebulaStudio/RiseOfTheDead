local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local UsableItems = {};
UsableItems.__index = UsableItems;
--== Script;

function UsableItems:Init(library)
	local function new(obj)
		if obj.ClassName ~= "ModuleScript" or obj.Name == "UsablePreset" then return end;
		local data = require(obj);
		data.Id = obj.Name;
		library:Add(data);
	end

	for _, obj in pairs(script:GetChildren()) do
		new(obj);
	end
	script.ChildAdded:Connect(function(obj)
		new(obj);
	end)
	
	local function add(data)
		local usableObj = require(script.Generics:FindFirstChild(data.Type));
		usableObj.__index = usableObj;
		
		local self = data;
		setmetatable(self, usableObj);
		
		library:Add(self);
	end
	
	--== Skin Permanent
	local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
	local itemLibList = modItemsLibrary.Library:ListByMatchFunc(function(itemLib)
		return modItemsLibrary:HasTag(itemLib.Id, "Skin Perm");
	end)

	for a=1, #itemLibList do
		local itemLib = itemLibList[a];
		
		add{
			Id=itemLib.Id;
			Type="SkinPerm";
		}
	end
	
end

return UsableItems;