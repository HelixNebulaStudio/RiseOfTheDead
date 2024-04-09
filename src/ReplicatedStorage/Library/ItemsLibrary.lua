local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local toolsModule = game.ReplicatedStorage.Library.Tools;

local Item = {};
Item.Script = script;

Item.SearchTags = {};
Item.ItemNames = {};
Item.Library = modLibraryManager.new();

Item.Types = {
	None="None";
	Tool="Tool";
	Resource="Resource";
	Blueprint="Blueprint";
	Mod="Mod";
	Mission="Mission";
	Key="Key";
	Component="Component";
	Clothing="Clothing";
	Commodity="Commodity";
	Structure="Structure";
	Food="Food";
	Usable="Usable";
	Ammo="Ammo";
	Token="Token";
};

Item.Tradable = {
	Nontradable="Nontradable";
	Tradable="Tradable";
	PremiumOnly="Non-premium Tax";--"PremiumOnly";
}

Item.TypeIcons = {
	[Item.Types.Resource]="rbxassetid://1551799903";
	[Item.Types.Blueprint]="rbxassetid://1549032830";
	[Item.Types.Component]="rbxassetid://1549035845";
	[Item.Types.Commodity]="rbxassetid://3598790816";
	[Item.Types.Mission]="rbxassetid://1550983590";
	[Item.Types.Food]="rbxassetid://4466529123";
	[Item.Types.Structure]="rbxassetid://4466529235";
	[Item.Types.Clothing]="rbxassetid://4789549007";
	[Item.Types.Ammo]="rbxassetid://7252704415";
};


local rgb255 = Color3.fromRGB(255, 255, 255);
local function getrgb255() return rgb255; end;

Item.TierColors = {
	nil;
	Color3.fromRGB(63, 130, 255);
	Color3.fromRGB(150, 89, 255);
	Color3.fromRGB(165, 59, 168);
	Color3.fromRGB(255, 122, 122);
	Color3.fromRGB(255, 133, 52);
}

setmetatable(Item.TierColors, {__index=getrgb255;});
--== Script;
local baseItem = {
	Id = "n/a";
	Name = "n/a";
	Description = "n/a";
	Stackable = false;
	Icon = "rbxassetid://9617595460";
	Tags = {};
	
	Tradable = Item.Tradable.Nontradable;
}
baseItem.__index = baseItem;

function Item:Find(key)
	return Item.Library:Find(key);
end

function Item:HasTag(key, tag)
	if Item.SearchTags[key] and table.find(Item.SearchTags[key], tag) then
		return true;
	end
	return false;
end

function Item:GetTags(key)
	return Item.SearchTags[key];
end

function Item:Add(data)
	return Item.Library:Add(data);
end

Item.Library:SetOnAdd(function(data)
	if data.OnAdd then data.OnAdd(data); end
	
	local tags = rawget(data, "Tags") or {};
	table.insert(tags, data.Name);
	table.insert(tags, data.Type);
	
	local meta = getmetatable(data);
	if meta then
		if meta.Tags then
			for a=1, #meta.Tags do
				table.insert(tags, meta.Tags[a]);
			end
		end
		
		setmetatable(meta, baseItem);
	else
		setmetatable(data, baseItem);
	end

	data.Tags = tags;
	data.Equippable = data.Equippable == true 
		or data.Type == Item.Types.Structure 
		or data.Type == Item.Types.Tool 
		or data.Type == Item.Types.Food 
		or toolsModule:FindFirstChild(data.Id) ~= nil;

	data.CanDelete = (data.Id ~= "p250" and data.Type ~= Item.Types.Mission and 0 or 1);

	if modBranchConfigs.CurrentBranch.Name == "Dev" then
		data.CanDelete = 0;
	end

	Item.ItemNames[data.Name] = data.Id;
	Item.ItemNames[string.lower(data.Name)] = data.Id;
	Item.SearchTags[data.Id] = tags;
end)


local function loadModule(moduleScript)
	if not moduleScript:IsA("ModuleScript") then return end;

	local itemLib = Item:Find(moduleScript.Name);
	if itemLib == nil then return end;
	
	local itemPacket = require(moduleScript);
	for k, v in pairs(itemPacket) do
		itemLib[k] = v;
	end
	
	if itemPacket.Init then
		task.spawn(itemPacket.Init, itemLib);
	end
end
script.ChildAdded:Connect(loadModule);


local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local moddedSelf = modModEngineService:GetModule(script.Name);
if moddedSelf then moddedSelf:Init(Item); end

for _, obj in pairs(script:GetChildren()) do
	loadModule(obj);
end

return Item;







