local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local localPlayer = game.Players.LocalPlayer;

local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

local StatusClass = require(script.Parent.StatusClass).new();
--==

local statusVisibility = false;
function StatusClass.OnTick(classPlayer, status, tickPack)
	if status.Visible == nil then status.Visible = statusVisibility; end
	
	if RunService:IsClient() then return end;
	if tickPack.ms1000 ~= true then return end;
	
	local humanoid = classPlayer.Humanoid;
	
	local properties = classPlayer.Properties;
	local sync = false;
	
	local equippedTools = classPlayer:GetEquippedTools();
	local itemId = equippedTools and equippedTools.ItemId;
	local isMeleeEquipped = itemId and (modItemsLibrary:HasTag(itemId, "Melee"))
	
	if isMeleeEquipped and not status.Visible then
		status.Visible = true;
		sync = true;
		
	elseif not isMeleeEquipped and status.Visible then
		status.Visible = false;
		sync = true;
		
	end
	
	return sync;
end

return StatusClass;
