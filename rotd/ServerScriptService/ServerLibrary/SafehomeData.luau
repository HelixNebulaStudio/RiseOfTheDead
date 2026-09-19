local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local SafehomeData = {};
SafehomeData.__index = SafehomeData;

--==
local TweenService = game:GetService("TweenService");

local audioModule = game.ReplicatedStorage.Library.Audio;

local modRemotesManager = shared.require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);

local modSafehomesLibrary = shared.require(game.ReplicatedStorage.Library.SafehomesLibrary);
local modNpcProfileLibrary = shared.require(game.ReplicatedStorage.Library.NpcProfileLibrary);
local modStoragePresetLibrary = shared.require(game.ReplicatedStorage.Library.StoragePresetsLibrary);

local modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
local modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);
local modSafehomeService = shared.require(game.ServerScriptService.ServerLibrary.SafehomeService);

local remoteSafehomeRequest;

local randomColors = {
	Color3.fromRGB(255, 0, 0),
	Color3.fromRGB(0, 255, 255),
	Color3.fromRGB(0, 255, 0),
	Color3.fromRGB(255, 255, 0),
	Color3.fromRGB(0, 0, 255),
	Color3.fromRGB(255, 0, 255)
};

local lightSources = {};
local soundSources = {};

local partyLightsDebounce = false;
local isSoundPlaying = false;

--== Script;
function SafehomeData.onRequire()
	remoteSafehomeRequest = modRemotesManager:Get("SafehomeRequest");

	function remoteSafehomeRequest.OnServerInvoke(player, actionId, packet)
		Debugger:StudioWarn("remoteSafehomeRequest", player, actionId, packet);
		if remoteSafehomeRequest:Debounce(player) then return {ReplyCode=3;} end;
		local profile = shared.modProfile:Get(player);
		if profile == nil then return {ReplyCode=5;} end;

		local traderProfile = profile.Trader;

		local safehomeData = profile.Safehome;
		local safehomeClass = safehomeData.SafehomeClass;

		local worldSafehomeClass = shared.WorldCore.SafehomeClass;

		if actionId == "fetch" then
			if safehomeData then
				safehomeData.UpdateFoodSupply();
				return {ReplyCode=1; Data=safehomeData;};
			end
			
			return {ReplyCode=5;};

		elseif actionId == "purchaseSafehome" then
			local safehomeId = packet.SafehomeId;
			if safehomeId == nil then return {ReplyCode=5;} end;
			
			local safehomeLib = modSafehomesLibrary:Find(safehomeId);
			if safehomeLib == nil then return {ReplyCode=5;} end;
			safehomeId = safehomeLib.Id;
			
			local playerGold = traderProfile.Gold;
			local price = safehomeLib.Price;

			if playerGold >= price then
				safehomeData.Homes[safehomeId] = {};
				
				traderProfile:AddGold(-price);
				
				modAnalyticsService:Sink{
					Player = player;
					Currency = modAnalyticsService.Currency.Gold;
					Amount = price;
					EndBalance = traderProfile.Gold;
					ItemSKU = `Unlock:{safehomeId}`;
				};

				return {ReplyCode=1; Data=safehomeData;};
				
			else
				return {ReplyCode=2;};
				
			end
			
			
		elseif actionId == "setSafehome" then
			local mission78 = modMission:GetMission(player, 78);
			if mission78 and mission78.Type == 1 and mission78.ProgressionPoint >= 2 then
				shared.Notify(player, "Can not switch safehome during The Killer Hues.", "Negative");
				return {ReplyCode=4;};
			end

			local factionGroup = shared.WorldCore.FactionGroupCache; -- faction world;
			if factionGroup then
				if factionGroup.HqHost ~= player.Name then
					shared.Notify(player, "Headquarters hosted by ".. factionGroup.HqHost ..", cannot set headquarters.", "Negative");
					return {ReplyCode=4;};
				end
				
			else
				if not modBranchConfigurations.IsWorld("Safehome") or safehomeClass == nil then
					shared.Notify(player, "This is not your safehome.", "Negative");
					return {ReplyCode=4;};
				end;
				
			end
			
			local safehomeId = packet.SafehomeId;
			if safehomeId == nil then return {ReplyCode=5;} end;
			
			local safehomeLib = modSafehomesLibrary:Find(safehomeId);
			if safehomeLib == nil then return {ReplyCode=5;} end;
			safehomeId = safehomeLib.Id;
			
			if safehomeLib.Unlocked ~= true and safehomeData.Homes[safehomeId] == nil then return {ReplyCode=5;} end;
			
			safehomeData.ActiveId = safehomeId;
			if factionGroup then
				factionGroup.SafehomeId = safehomeId;
				
				local modFactions = shared.require(game.ServerScriptService.ServerLibrary.Factions);
				local setReturnPacket = modFactions.Database:UpdateRequest(factionGroup.Tag, "sethqhost", {
					UserId=tostring(player.UserId);
					SafehomeId=safehomeId
				});
				
				factionGroup = setReturnPacket.Data;
			end
				
			if modBranchConfigurations.IsWorld("Safehome") then
				safehomeClass:ChangeMap(safehomeId);
			end
			
			return {ReplyCode=1; Data=safehomeData;};
			
			
		elseif actionId == "customizeSafehome" then
			local homeData = safehomeData.Homes[safehomeData.ActiveId];
			
			if homeData == nil then
				safehomeData.Homes[safehomeData.ActiveId] = {};
				homeData = safehomeData.Homes[safehomeData.ActiveId];
			end
			
			if homeData.Customization == nil then
				homeData.Customization = {};
			end
			
			local groupId = packet.GroupId;
			if homeData.Customization[groupId] == nil then
				homeData.Customization[groupId] = {};
			end
			
			local groupData = homeData.Customization[groupId];
			
			if packet.NewColor and typeof(packet.NewColor) == "Color3" then
				groupData.Color = packet.NewColor:ToHex();
			end
			
			local returnColor = Color3.fromHex(groupData.Color);
			
			if modBranchConfigurations.IsWorld("Safehome") and safehomeClass then
				local safehomeCustomizableFolder = workspace.Environment:FindFirstChild("Customizable");
				local groupFolder = safehomeCustomizableFolder and safehomeCustomizableFolder:FindFirstChild(groupId);
				
				if groupFolder then
					for _, obj in pairs(groupFolder:GetChildren()) do
						if obj:IsA("BasePart") then
							obj.Color = returnColor;
						end
					end
				end
			end
			
			return {
				ReturnColor=returnColor;
			}
			
			
		elseif actionId == "kickSurvivor" then
			local npcName = packet.Name or "";
			
			local npcData = safehomeData:GetNpc(npcName);
			if npcData == nil or npcData.Active == nil then return {ReplyCode=5; Data=safehomeData;} end;
			
			local npcStorage = npcData.GetStorage();

			if npcStorage and npcStorage:Loop() > 0 then
				shared.Notify(player, `You should remove the items from {npcName} before kicking them.`, "Negative");
				return {ReplyCode=5; FailMsg=`Remove {npcName}'s items first`;}
			end

			npcData.Active = nil;
			
			if modBranchConfigurations.IsWorld("Safehome") and safehomeClass then
				local npcClass: NpcClass = safehomeClass.NpcClassList[npcName];
				if npcClass then
					npcClass:Destroy();
				end
				safehomeClass.NpcClassList[npcName] = nil;
			end
			
			return {ReplyCode=1; Data=safehomeData;};
		end
		
		if not modBranchConfigurations.IsWorld("Safehome") then return end;
		--== Safehome only functions;
		


		if actionId == "inspectSafehome" then
			if safehomeClass == nil or safehomeClass.Owner ~= player or safehomeClass.FactionTag then
				shared.Notify(player, "You are not at your safehome world.", "Negative");
				return {ReplyCode=4;};
			end;
			
			local safehomeId = packet.SafehomeId;
			local safehomeLib = modSafehomesLibrary:Find(safehomeId);
			if safehomeLib == nil then return {ReplyCode=5;} end;
			
			safehomeClass:ChangeMap(safehomeId);
			if safehomeLib.Unlocked ~= true or safehomeData.Homes[safehomeId] == nil then
				safehomeClass:SetInspectMode(true);
			end
			

		elseif actionId == "playSound" and safehomeData.ActiveId ~= "default" then
			local soundId = packet.SoundId;
			local interactConfig = packet.InteractConfig;

			if soundId == nil or #soundId <= 0 then
				local soundList = {};
				for _, sound in pairs(audioModule.ServerAudio:GetChildren()) do
					if sound.TimeLength > 59 then
						table.insert(soundList, sound.SoundId);
					end
				end
				
				soundId = soundList[math.random(1, #soundList)];
			end
			
			if soundId:match("rbxassetid") == nil then
				soundId = `rbxassetid://{soundId}`;
			end
			
			local globalAudioPlayer: AudioPlayer = workspace:FindFirstChild("GlobalSoundSystem");
			local audioReverb = globalAudioPlayer and globalAudioPlayer:FindFirstChild("AudioReverb");
			if globalAudioPlayer == nil then
				globalAudioPlayer = Instance.new("AudioPlayer");
				audioReverb = Instance.new("AudioReverb");
				audioReverb.Parent = globalAudioPlayer;
				
				local wire = Instance.new("Wire");
				wire.Parent = globalAudioPlayer;
				wire.SourceInstance = globalAudioPlayer;
				wire.TargetInstance = audioReverb;
			end
			globalAudioPlayer.Name = "GlobalSoundSystem";
			globalAudioPlayer.Looping = true;
			globalAudioPlayer.Parent = workspace;
			
			if globalAudioPlayer.IsPlaying then
				globalAudioPlayer:Stop();
				return;
			end
			
			local audioEmitters: {AudioEmitter} = {};

			if packet.RadioPlay ~= true then
				local mapAudioEmitters = workspace.Environment:FindFirstChild("AudioEmitters");
				if mapAudioEmitters then
					for _, obj in ipairs(mapAudioEmitters:GetDescendants()) do
						if obj:IsA("BasePart") then
							(obj::BasePart).AudioCanCollide = false;

						elseif obj:IsA("AudioEmitter") then
							(obj :: AudioEmitter):SetDistanceAttenuation(modAudio.newDistanceAttenuation("InverseTapered"));
							table.insert(audioEmitters, obj);
						end;
					end
				end
			end

			local radioAudioEmitterAtt = interactConfig:FindFirstChild("RadioAudioEmitterAtt");
			local radioAudioEmitter = radioAudioEmitterAtt and radioAudioEmitterAtt:FindFirstChild("RadioAudioEmitter");
			if radioAudioEmitter == nil then
				radioAudioEmitterAtt = Instance.new("Attachment");
				radioAudioEmitterAtt.Parent = interactConfig;
				radioAudioEmitterAtt.CFrame = CFrame.new(-1, 0, 0);
				
				radioAudioEmitter = Instance.new("AudioEmitter");
				radioAudioEmitter.Name = "RadioAudioEmitter";
				radioAudioEmitter:SetDistanceAttenuation(modAudio.newDistanceAttenuation("InverseTapered", 14, 120));
				radioAudioEmitter.Parent = radioAudioEmitterAtt;
			end
			table.insert(audioEmitters, radioAudioEmitter);

			for _, audioEmitter in ipairs(audioEmitters) do
				if audioEmitter:FindFirstChild("Wire") then continue end;

				local wire = Instance.new("Wire");
				wire.Parent = audioEmitter;
				wire.SourceInstance = audioReverb;
				wire.TargetInstance = audioEmitter;
			end

			globalAudioPlayer.Asset = soundId;
			globalAudioPlayer:Play();

		elseif actionId == "togglePartyLights" and safehomeData.ActiveId ~= "default" then
			local interactConfig = packet.InteractConfig;
			if interactConfig == nil then return end;
			
			if #lightSources <= 0 then
				local lightsGroup = workspace.Environment:FindFirstChild("Game") 
								and workspace.Environment.Game:FindFirstChild("TogglableLights") or nil;
				local safehouseLights = lightsGroup:GetDescendants();
				
				for a=1, #safehouseLights do
					if safehouseLights[a].Name == "_lightSource" then
						local lightTable = {Source=safehouseLights[a]; OriginalColor=safehouseLights[a].Color; LightObjects={}};
						local lights = safehouseLights[a]:GetDescendants();
						for b=1, #lights do
							if lights[b]:IsA("Light") then
								table.insert(lightTable.LightObjects, {Light=lights[b]; OriginalColor=lights[b].Color});
							end
						end
						table.insert(lightSources, lightTable);
					end
				end
			end
			
			local partyLightsActive = workspace:GetAttribute("PartyLights");
			
			if partyLightsActive then
				workspace:SetAttribute("PartyLights", false);
				
			else
				if partyLightsDebounce then return end;
				partyLightsDebounce = true;
				workspace:SetAttribute("PartyLights", true);
				
				task.spawn(function()
					while workspace:GetAttribute("PartyLights") do
						for a=1, #lightSources do
							local newColor = randomColors[math.random(1, #randomColors)];
							local tween = TweenService:Create(lightSources[a].Source, TweenInfo.new(math.random(50, 99)/100), {Color=newColor});
							for b=1, #lightSources[a].LightObjects do
								local bTween = TweenService:Create(lightSources[a].LightObjects[b].Light, TweenInfo.new(math.random(50, 99)/100), {Color=newColor});
								bTween:Play();
							end
							tween:Play();
						end
						task.wait(1);
					end
					local resetTime = 5;
					for a=1, #lightSources do
						local tween = TweenService:Create(lightSources[a].Source, TweenInfo.new(resetTime), {Color=lightSources[a].OriginalColor});
						for b=1, #lightSources[a].LightObjects do
							local bTween = TweenService:Create(lightSources[a].LightObjects[b].Light, TweenInfo.new(resetTime), {Color=lightSources[a].LightObjects[b].OriginalColor});
							bTween:Play();
						end
						tween:Play();
					end
					partyLightsDebounce = false;
				end)
			end
			
		end
		
		return {};
	end
end

function SafehomeData.new(player)
	local meta = {
		Player = player;
		UpdateFoodSupply = function()end;
		SafehomeClass = nil;
	};
	meta.__index=meta;
	
	local self = {
		ActiveId="default";
		Homes={};
		Npc={};
	};
	
	setmetatable(self, meta);
	setmetatable(meta, SafehomeData);
	
	return self;
end

function SafehomeData:Destroy()
	Debugger:StudioWarn(`SafehomeData:Destroy()`);
end

function SafehomeData:SetMetaSafehomeClass(safehomeClass)
	getmetatable(self).SafehomeClass = safehomeClass;
end

--[[
	SafehomeData:GetNpc(npcName: string)

	@param npcName Name of npc.
	@return npcData metatable is shared serverside 
]]
function SafehomeData:GetNpc(npcName: string)
	local npcLib = modNpcProfileLibrary:Find(npcName);
	if npcLib == nil then return end;

	local npcPropLib = modNpcProfileLibrary:GetProperties(npcName);
	local npcData = self.Npc[npcName];

	local npcDataMeta = {};
	function npcDataMeta:__index(k)
		if k == "Active" then
			if npcLib.SafehomeActive then return true end;
		end

		local v = rawget(self, k);
		if v ~= nil then
			return v;
		end

		v = npcDataMeta[k];
		if v ~= nil then
			return v;
		end

		return npcPropLib[k];
	end

	function npcDataMeta:SetGetStorage(f)
		npcDataMeta.GetStorage = f;
	end

	if npcData == nil then
		npcData = setmetatable({}, npcDataMeta);
		self.Npc[npcName] = npcData;

	else
		setmetatable(npcData, npcDataMeta);
	end
	
	
	local storagePresetLib = modStoragePresetLibrary:Find("npcstorage");
	local storageId = `{npcName}Storage`;

	local storage = modStorage.openStorage(storageId, {
		Player = self.Player;
		
		StorageName = `{npcName} Storage`;
		StoragePresetLib = storagePresetLib;

		Properties = {
			NpcName = npcName;
		};
	});
	npcData:SetGetStorage(function()
		return storage;
	end);

	return npcData;
end

function SafehomeData:Load(data)
	for k, v in pairs(data) do
		self[k] = v;
		
	end
	return self;
end

function SafehomeData:Init()
	local activeNpcs = 0;
	for name, npcData in pairs(self.Npc) do
		if npcData == nil or npcData.Active ~= true then continue end;
		activeNpcs = activeNpcs +1;
	end

	local updateFoodSupply = function()
		Debugger:StudioWarn("Update Food Supply");
		local freezerStorage = shared.modStorage.Get("Freezer", self.Player);
		if freezerStorage == nil then return end;

		local freezerSize = freezerStorage.Size;
		local foodSupply = 0;

		local orderedFoodList = {};
		freezerStorage:Loop(function(storageItem)
			local itemLib = modItemsLibrary:Find(storageItem.ItemId);
			if itemLib and itemLib.Type == modItemsLibrary.Types.Food then
				foodSupply = foodSupply + storageItem.Quantity;
				table.insert(orderedFoodList, storageItem);
			end
		end)
		self.FoodSupply = foodSupply;
		self.MaxFoodSupply = freezerSize*10;

		table.sort(orderedFoodList, function(a, b) return a.Index > b.Index end);
		

		if self.LastFoodUpdate == nil then self.LastFoodUpdate = os.time(); end
		local timelapseSec = os.time()-self.LastFoodUpdate;
		if timelapseSec < 60 then return end;
		self.LastFoodUpdate = os.time();

		local minsPassed = math.ceil(timelapseSec/60);
		
		for npcName, _ in pairs(self.Npc) do
			if self.Npc[npcName].Active == nil then continue end;
			local npcData = self:GetNpc(npcName);

			local hungerR = npcData.HungerRate/1440;
			local hungerV = npcData.Hunger or 0;
			npcData.Hunger = math.clamp(hungerV - (hungerR * minsPassed), 0, 1);

			Debugger:StudioWarn(`{npcName} new hunger: {npcData.Hunger}`);

			for a=1, 3 do
				if npcData.Hunger > 0.7 then break; end;
				if foodSupply <= 0 then break; end;

				local storageItem = orderedFoodList[1];
				if storageItem == nil or storageItem.Quantity <= 0 then break end;

				freezerStorage:Remove(storageItem.ID, 1);
				npcData.Hunger = math.clamp(hungerV +(math.random(250,300)/1000), 0, 1);
				Debugger:StudioWarn(`{npcName} eats: {npcData.Hunger}`);

				if storageItem.Quantity <= 0 then
					table.remove(orderedFoodList, 1);
				end
			end
		end

		self:RefreshStats();
	end

	local meta = getmetatable(self);
	meta.UpdateFoodSupply = updateFoodSupply;
end

function SafehomeData:RefreshStats()
	for npcName, _ in pairs(self.Npc) do
		if self.Npc[npcName].Active == nil then continue end;
		local npcData = self:GetNpc(npcName);

		if npcData.CalculateHappiness then
			npcData:CalculateHappiness();
		end
	end
end


return SafehomeData;
