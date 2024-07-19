local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local TweenService = game:GetService("TweenService");
local CollectionService = game:GetService("CollectionService");

local localplayer = game.Players.LocalPlayer;
local modData = require(localplayer:WaitForChild("DataModule"));
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modFormatNumber = require(game.ReplicatedStorage.Library.FormatNumber);
local modGameModeLibrary = require(game.ReplicatedStorage.Library.GameModeLibrary);
local modDamagable = Debugger:Require(game.ReplicatedStorage.Library.Damagable);
local modMarkers = require(game.ReplicatedStorage.Library.Markers);

local mainFrame = script.Parent.Parent:WaitForChild("EntityHealthHud");
local bossHealthBarTemplate = script:WaitForChild("bossHealth");

local remoteTryHookEntity = modRemotesManager:Get("TryHookEntity");

Interface.EntityHealthBars = {};

local tempSoundtrackLib = {
	["Winter Treelum"]="Soundtrack:Silver Tree";
	["Treelum"]="Soundtrack:Insurgent";
}

local activeSndTracks = {};
local lastTrackChange = tick();

local closeHudTimer = 30;

local fullHealthColor, emptyHealthColor = Color3.fromRGB(36, 140, 49), Color3.fromRGB(207, 50, 50);
--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);
	
	for bossName, info in pairs(modGameModeLibrary.GameModes.Boss.Stages) do
		if info.Soundtrack then
			tempSoundtrackLib[bossName] = info.Soundtrack;
		end
		
		if info.Prefabs then
			for prefabName, _ in pairs(info.Prefabs) do
				tempSoundtrackLib[prefabName] = info.Soundtrack;
			end
		end
	end
	
	local window = Interface.NewWindow("EntityHealthHud", mainFrame);
	window.IgnoreHideAll = true;
	window.ReleaseMouse = false;
	window:SetOpenClosePosition(UDim2.new(0, 0, 0, 0), UDim2.new(0, 0, -1.1, 0));
	
	Interface.Garbage:Tag(function()
		table.clear(Interface.EntityHealthBars);
	end);
	
	function Interface.UpdateVisiblity()
		local closestLastHit = math.huge;
		local lastHitName;
		
		local c = 0;
		for prefab, info in pairs(Interface.EntityHealthBars) do
			local humanoid = prefab:FindFirstChildWhichIsA("Humanoid");
			
			if humanoid and humanoid.Health > 0 then
				c = c+1;
			end
			
			local d = tick()-info.LastTick;
			if d < closestLastHit then
				closestLastHit = d;
				lastHitName = info.Name;
				
				if prefab:GetAttribute("Soundtrack") then
					tempSoundtrackLib[lastHitName] = prefab:GetAttribute("Soundtrack");
				end
			end
		end
		
		window:Toggle(c>0);
		
		local function clearActiveTracks(excludeName)
			for name, soundObj in pairs(activeSndTracks) do
				if soundObj.IsPlaying and name ~= excludeName then
					TweenService:Create(soundObj, TweenInfo.new(3), {Volume=0;}):Play();
					task.delay(3, function()
						game.Debris:AddItem(activeSndTracks[name], 0);
						activeSndTracks[name] = nil;
					end)
				end
			end
			
		end
		
		if c > 0 and lastHitName and tempSoundtrackLib[lastHitName] then
			local trackName = tempSoundtrackLib[lastHitName];
			
			clearActiveTracks(trackName);
			
			if tick()-lastTrackChange >= 6 then
				lastTrackChange = tick();
				
				if activeSndTracks[trackName] == nil or not activeSndTracks[trackName].IsPlaying then
					modAudio.Preload(trackName, 5);
					local sound = modAudio.Play(trackName, mainFrame);
					sound.Volume = 0;
					activeSndTracks[trackName] = sound;

					TweenService:Create(sound, TweenInfo.new(6), {Volume=1;}):Play();
				end
			end
			
		else
			clearActiveTracks();
			
		end
		
	end
	
	Interface.Garbage:Tag(remoteTryHookEntity.OnClientEvent:Connect(Interface.TryHookEntity));
	Interface.Garbage:Tag(CollectionService:GetInstanceAddedSignal("Deadbody"):Connect(function(prefab)
		local entityHpBarData = Interface.EntityHealthBars[prefab]; 
		if entityHpBarData and entityHpBarData.ClearBossHealthCheck then
			entityHpBarData.ClearBossHealthCheck();
		end
	end))
	
	return Interface;
end;

function Interface.TryHookEntity(prefab, closeTime)
	if prefab == nil then return end;
	if prefab:GetAttribute("EntityHudHealth") == true then
		Interface.HookEntity(prefab, closeTime);
	end
	
	Interface.UpdateVisiblity();
end


function Interface.HookEntity(prefab: Actor, closeTime)
	if prefab:HasTag("Deadbody") then return end;
	local prefabName = prefab.Name;
	
	local playerGui = game.Players.LocalPlayer.PlayerGui;
	
	local bossNameTag = mainFrame.Boss.bossName;
	local statusTag = mainFrame.Boss.status;
	local hpBarsList = mainFrame.Boss.bossHealthBars;
	
	local damagable = modDamagable.NewDamagable(prefab);
	if damagable == nil then return end;
	
	local healthInfo = damagable:GetHealthInfo();
	
	local entityHpBarData = Interface.EntityHealthBars[prefab];
	
	if entityHpBarData then
		entityHpBarData.LastTick = tick();
		
	end
	
	if healthInfo and entityHpBarData == nil then
		local newHealthbar = bossHealthBarTemplate:Clone();
		newHealthbar.Parent = hpBarsList;
		
		Interface.EntityHealthBars[prefab] = {Name=prefabName; HealthBar=newHealthbar; LastTick=tick(); CloseTime=closeTime;};
		entityHpBarData = Interface.EntityHealthBars[prefab];

		local healthBarLabel = newHealthbar:WaitForChild("label");
		local healthBarBar = newHealthbar:WaitForChild("Bar");

		local updateHpConn
		local previousHealth = healthInfo.Health;
		
		local function updateEntityHealth()
			healthInfo = damagable:GetHealthInfo();
			
			task.wait();
			if prefab == nil then return; end
			if not healthBarLabel:IsDescendantOf(playerGui) then updateHpConn:Disconnect() return end;
			if not healthBarBar:IsDescendantOf(playerGui) then updateHpConn:Disconnect() return end;

			local healthPercent = healthInfo.Health/healthInfo.MaxHealth;
			
			
			healthBarLabel.Text = prefab.Name..": "..
				modFormatNumber.Beautify(math.clamp(math.ceil(healthInfo.Health), 0, healthInfo.MaxHealth)).." / "..modFormatNumber.Beautify(healthInfo.MaxHealth);

			healthBarBar:TweenSize(UDim2.new(math.clamp(1*healthPercent, 0, 1), 0, 1, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true);
			delay(0.05, function()
				newHealthbar.LostBar:TweenSize(UDim2.new(math.clamp(1*healthPercent, 0, 1), 0, 1, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.5, true);
			end)

			previousHealth = healthInfo.Health;
			
			if previousHealth <= 0 then
				Interface.UpdateVisiblity();
			end

			local markerName = prefab.Name;
			modMarkers.SetColor(markerName, emptyHealthColor:Lerp(fullHealthColor, math.clamp(1*healthPercent, 0, 1)));
			
		end
		updateEntityHealth();
		updateHpConn = damagable:GetHealthChangedSignal():Connect(updateEntityHealth)

		local function delHealthBar()
			Debugger.Expire(newHealthbar, 1);
			Interface.EntityHealthBars[prefab] = nil;
			
			Interface.UpdateVisiblity();
		end
		
		prefab.Destroying:Connect(delHealthBar)
		
		local closeTimeHud = (entityHpBarData.CloseTime or closeHudTimer);
		local function clearBossHealthCheck()
			if entityHpBarData == nil then return end;
			
			if (tick()-entityHpBarData.LastTick) > closeTimeHud or prefab:HasTag("Deadbody") == true then
				delHealthBar();
				return;
			end
			
			task.delay(closeTimeHud, clearBossHealthCheck);
		end
		task.delay(closeTimeHud, clearBossHealthCheck);

		entityHpBarData.ClearBossHealthCheck = clearBossHealthCheck;
	end
end

--Interface.Garbage is only initialized after .init();
return Interface;