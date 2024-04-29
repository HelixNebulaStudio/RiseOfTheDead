local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local IconPriority = {Mission=3; Heal=6; Guide=9;};
--== Variables;
local HeadIcons = {};
local localplayer = game.Players.LocalPlayer;
local TweenService = game:GetService("TweenService");

local modData = require(localplayer:WaitForChild("DataModule") :: ModuleScript);
local modMissionLibrary = require(game.ReplicatedStorage.Library.MissionLibrary);
local modNpcProfileLibrary = require(game.ReplicatedStorage.BaseLibrary.NpcProfileLibrary);

local missionIconPrefab = game.ReplicatedStorage:WaitForChild("Prefabs"):WaitForChild("Objects"):WaitForChild("MissionIcon");
local healIconPrefab = game.ReplicatedStorage:WaitForChild("Prefabs"):WaitForChild("Objects"):WaitForChild("HealIcon");
local guideIconPrefab = game.ReplicatedStorage:WaitForChild("Prefabs"):WaitForChild("Objects"):WaitForChild("GuideIcon");

local remotes = game.ReplicatedStorage:WaitForChild("Remotes");
local remoteSetHeadIcon = remotes:WaitForChild("SetHeadIcon");

local Icons = {};
--== Script;
function RefreshIcon(npcName)
	if Icons[npcName] == nil then return end;
	
	local function DestroyIcon()
		if Icons[npcName].Prefab ~= nil then
			Icons[npcName].Prefab:Destroy();
			Icons[npcName].Prefab = nil;
		end
	end
	
	if modData.GameSave and modData.GameSave.Missions then
		local missionsList = modData.GameSave.Missions;
		local missionActive = false;
		for a=1, #missionsList do
			local missionData = missionsList[a];
			local missionLib = modMissionLibrary.Get(missionData.Id);
			if missionLib.From == npcName and missionData.Type == 1 then
				missionActive = true;
				break;
			end
		end
		local npcLib = modNpcProfileLibrary:Find(npcName);
		if npcLib and npcLib.HeadIcon and npcLib.HeadIcon == "Guide" then
			if missionActive then
				HeadIcons.Clear(npcName, npcLib.HeadIcon, false);
			else
				HeadIcons.Set(npcName, npcLib.HeadIcon, false);
			end
		end
	end
	
	if #Icons[npcName].List > 0 then
		table.sort(Icons[npcName].List, function(a, b) return (IconPriority[a] or 1) < (IconPriority[b] or 1); end);
		Icons[npcName].Active = Icons[npcName].List[1];
	else
		Icons[npcName].Active = nil;
	end
	if Icons[npcName].Active then
		DestroyIcon();
		local npc = workspace.Entity:FindFirstChild(npcName);
		local npcHead = npc and npc:FindFirstChild("Head") or nil;
		if npcHead then
			local new;
			if Icons[npcName].Active == "Mission" then
				new = missionIconPrefab:Clone();
			elseif Icons[npcName].Active == "Heal" then
				new = healIconPrefab:Clone();
			elseif Icons[npcName].Active == "Guide" then
				new = guideIconPrefab:Clone();
			end 
			if new then
				new.Parent = npc;
				local weld = Instance.new("Weld");
				weld.Parent = new;
				weld.Part0 = new;
				weld.Part1 = npcHead;
				weld.C0 = CFrame.new(0, -2, 0) * CFrame.Angles(0, math.rad(180), 0);
				TweenService:Create(weld, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {C0=(CFrame.new(0, -2.5, 0) * CFrame.Angles(0, 0, 0))}):Play();
				new.Anchored = false;
				Icons[npcName].Prefab = new;
			end
		end
	else
		DestroyIcon();
	end
end

function HeadIcons.Set(npcName, iconType, refresh)
	if npcName == nil or #npcName <= 0 then return end;
	if Icons[npcName] == nil then Icons[npcName] = {List={}}; end;
	local exist = false;
	for a=1, #Icons[npcName].List do
		if Icons[npcName].List[a] == iconType then
			exist = true;
		end
	end
	if not exist then
		table.insert(Icons[npcName].List, iconType);
	end
	if refresh ~= false then
		RefreshIcon(npcName)
	end
end

function HeadIcons.GetIcons()
	return Icons;
end

function HeadIcons.Clear(npcName, iconType, refresh)
	if Icons[npcName] and Icons[npcName].List then
		for a=#Icons[npcName].List, 1, -1 do
			if Icons[npcName].List[a] == iconType or iconType == "HideAll" then
				table.remove(Icons[npcName].List, a);
			end
		end
	end
	if refresh ~= false then
		RefreshIcon(npcName)
	end
end

for npcName, npcLib in pairs(modNpcProfileLibrary:GetAll()) do
	if npcLib.HeadIcon == nil then continue end;
	HeadIcons.Set(npcName, npcLib.HeadIcon);
end

remoteSetHeadIcon.OnClientEvent:Connect(function(action, npcName, iconType)
	if action == 1 then
		HeadIcons.Set(npcName, iconType);
	elseif action == 0 then
		HeadIcons.Clear(npcName, iconType);
	end
end)
-- If clear and still exist, could be set by another dialogue remote fire.

return HeadIcons;