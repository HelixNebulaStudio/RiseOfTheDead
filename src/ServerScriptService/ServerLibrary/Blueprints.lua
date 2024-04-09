local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local Blueprints = {};
Blueprints.Profiles = nil;

local modBranchConfigs = Debugger:Require(game.ReplicatedStorage.Library.BranchConfigurations);
local modItemsLibrary = Debugger:Require(game.ReplicatedStorage.Library.ItemsLibrary);
local modRemotesManager = Debugger:Require(game.ReplicatedStorage.Library.RemotesManager);

local remoteHudNotification = modRemotesManager:Get("HudNotification");

--== Script;
function Blueprints.IsUnlocked(player, ...)
	local profile = shared.modProfile:Get(player);
	local activeSave = profile and profile:GetActiveSave();
	local blueprintSave = activeSave and activeSave.Blueprints;
	
	if blueprintSave then
		return blueprintSave:IsUnlocked(...);
	end
end

function Blueprints.UnlockBlueprint(player, ...)
	local profile = shared.modProfile:Get(player);
	local activeSave = profile and profile:GetActiveSave();
	local blueprintSave = activeSave and activeSave.Blueprints;
	
	if blueprintSave then
		blueprintSave:UnlockBlueprint(...);
	end
end

function Blueprints.new(player, syncFunc)
	local blueprintsMeta = {};
	blueprintsMeta.__index = blueprintsMeta;
	blueprintsMeta.Player = player;
	blueprintsMeta.Sync = syncFunc;
	blueprintsMeta.Size = 5;
	
	local blueprints = setmetatable({}, blueprintsMeta);
	blueprints.Unlocked = {};
	blueprints.Active = {};

	local modBlueprintLibrary = Debugger:Require(game.ReplicatedStorage.Library.BlueprintLibrary);
	
	function blueprintsMeta:UnlockBlueprint(itemId, data, sync)
		data = data or {};
		local library = modBlueprintLibrary.Get(itemId);
		
		if library == nil or library.CanUnlock == false then return end;
		
		if blueprints.Unlocked[itemId] == nil then
			blueprints.Unlocked[itemId] = {Time=data.Time or os.time();};
			if sync ~= false then
				remoteHudNotification:FireClient(self.Player, "Unlocked", {Name=library.Name});
			end
			if data.Time == nil and library.Category == "Commodities" then
				local profile = Blueprints.Profiles:Get(self.Player);
				local gameSave = profile:GetActiveSave();
				gameSave:AddStat("Perks", 20);
				shared.Notify(player, ("You recieved 20 Perks for learning the $Name."):gsub("$Name", library.Name), "Reward");
			end
		else
			sync = false;
		end
		if sync ~= false then
			blueprintsMeta:Sync();
		end
	end
	
	function blueprintsMeta:IsUnlocked(itemId)
		if blueprints.Unlocked[itemId] then
			return true;
		end
		return false;
	end
	
	local function newBuild(itemId, library, usingBlueprint)
		local buildTime = os.time()+library.Duration;
		
		if modBranchConfigs.CurrentBranch.Name == "Dev" then
			buildTime = os.time()+5;
		end;
		
		return {ItemId=itemId; BT=buildTime; Blueprint=usingBlueprint}
	end
	
	function blueprintsMeta:CanBuild()
		return #blueprints.Active < blueprintsMeta.Size;
	end
	
	function blueprintsMeta:NewBuild(itemId, usingBlueprint)
		local library = modBlueprintLibrary.Get(itemId);
		if library then
			table.insert(blueprints.Active, newBuild(itemId, library, usingBlueprint));
		end
		blueprintsMeta:Sync();
	end
	
	function blueprintsMeta:GetBuild(buildIndex)
		return blueprints.Active[buildIndex];
	end
	
	function blueprintsMeta:RemoveBuild(buildIndex)
		if blueprints.Active[buildIndex] ~= nil then
			table.remove(blueprints.Active, buildIndex);
		end
		blueprintsMeta:Sync();
	end
	
	function blueprintsMeta:Load(rawData, profile)
		for k, v in pairs(self) do
			local data = rawData[k] or self[k];
			if k == "Unlocked" then
				for id, bpdata in pairs(data) do
					self:UnlockBlueprint(id, bpdata, false);
				end
			elseif k == "Active" then
				for id, bpdata in pairs(data) do
					table.insert(blueprints.Active, bpdata);
				end
			end
		end
		return blueprints;
	end
	
	return blueprints;
end

return Blueprints;