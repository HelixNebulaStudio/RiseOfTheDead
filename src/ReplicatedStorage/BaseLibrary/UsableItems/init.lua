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
		Debugger:StudioWarn("Load usable", itemLib.Id);

		add{
			Id=itemLib.Id;
			Type="SkinPerm";
		}
	end

	-- -- MARK: arelshift
	-- add{
	-- 	Id="arelshiftcrossantique";
	-- 	Type="SkinPerm";
	-- };
	
	-- -- MARK: desolator
	-- add{
	-- 	Id="desolatorheavytoygun";
	-- 	Type="SkinPerm";
	-- };

	-- -- MARK: czevo3asiimov
	-- add{
	-- 	Id="czevo3asiimov";
	-- 	Type="SkinPerm";
	-- };

	-- -- MARK: rusty48
	-- add{
	-- 	Id="rusty48blaze";
	-- 	Type="SkinPerm";
	-- };
	
	-- -- MARK: sr308
	-- add{
	-- 	Id="sr308slaughterwoods";
	-- 	Type="SkinPerm";
	-- };
	-- add{
	-- 	Id="sr308horde";
	-- 	Type="SkinPerm";
	-- };

	-- -- MARK: vectorx
	-- add{
	-- 	Id="vectorxpossession";
	-- 	Type="SkinPerm";
	-- };
	
	-- -- MARK: deagle
	-- add{
	-- 	Id="deaglecryogenics";
	-- 	Type="SkinPerm";
	-- };
	
	-- -- MARK: flamethrower
	-- add{
	-- 	Id="flamethrowerblaze";
	-- 	Type="SkinPerm";
	-- };

end

return UsableItems;