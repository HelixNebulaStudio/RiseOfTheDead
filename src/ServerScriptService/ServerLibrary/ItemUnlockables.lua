local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local ItemUnlockables = {};
ItemUnlockables.__index = ItemUnlockables;
--==

local modItemUnlockablesLibrary = require(game.ReplicatedStorage.Library.ItemUnlockablesLibrary);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);

local remoteHudNotification = modRemotesManager:Get("HudNotification");

--== Script;
function ItemUnlockables.new(player)
	local meta = {
		Player=player;
	};
	meta.__index=meta;
	
	local self = {};
	
	setmetatable(self, meta);
	setmetatable(meta, ItemUnlockables);
	
	return self;
end

function ItemUnlockables:Load(data)
	for k, v in pairs(data) do
		self[k] = v;
	end
	return self;
end

function ItemUnlockables:Set(itemId, key, value)
	if self[itemId] == nil then
		self[itemId] = {};
	end
	
	self[itemId][key] = value;
end

function ItemUnlockables:Alert(itemId, key)
	local modItemUnlockableLib = modItemUnlockablesLibrary:Find(key);
	local itemLib = modItemsLibrary:Find(itemId);
	
	if modItemUnlockableLib and itemLib then
		local unlockedName = "Item Unlockable: "..modItemUnlockableLib.Name.." "..itemLib.Name;

		remoteHudNotification:FireClient(self.Player, "Unlocked", {Name=unlockedName;});
	end
end

return ItemUnlockables;
