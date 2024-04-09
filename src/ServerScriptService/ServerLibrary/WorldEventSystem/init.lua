local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local WorldEventSystem = {};
local random = Random.new();

local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);

local remoteHudNotification = modRemotesManager:Get("HudNotification");

WorldEventSystem.EventsTypes = {};
WorldEventSystem.NextEventTick = os.time()+1800;
WorldEventSystem.NextWorldEvent = "HordeAttack";
WorldEventSystem.ActiveEvent = nil;
WorldEventSystem.EndBind = Instance.new("BindableEvent");
--== Script;
for _, module in pairs(script:GetChildren()) do
	local mod = require(module);
	if mod.Initialize(WorldEventSystem) then
		table.insert(WorldEventSystem.EventsTypes, {Name=module.Name; Mod=mod});
	end
end

function WorldEventSystem:GetEvent(name)
	for a=1, #WorldEventSystem.EventsTypes do
		if WorldEventSystem.EventsTypes[a].Name == name then
			return WorldEventSystem.EventsTypes[a];
		end
	end
end

modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(function()
	if #WorldEventSystem.EventsTypes <= 0 then return end;
	if modSyncTime.GetTime() < WorldEventSystem.NextEventTick then return end;
	if WorldEventSystem.ActiveEvent then return end;
	
	WorldEventSystem.NextEventTick = modSyncTime.GetTime() + 10;
	
	local eventInfo = WorldEventSystem:GetEvent(WorldEventSystem.NextWorldEvent) or WorldEventSystem.EventsTypes[random:NextInteger(1, #WorldEventSystem.EventsTypes)];
	if eventInfo then
		WorldEventSystem.ActiveEvent = eventInfo;
		eventInfo.Mod.Start();
		WorldEventSystem.ActiveEvent = nil;
	end
	WorldEventSystem.NextWorldEvent = nil;
end)

WorldEventSystem.EndBind.Parent = script;
return WorldEventSystem;