local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local SafehomeData = {};
SafehomeData.__index = SafehomeData;

--==
local TweenService = game:GetService("TweenService");

local audioModule = game.ReplicatedStorage.Library.Audio;

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);

local modSafehomesLibrary = shared.require(game.ReplicatedStorage.Library.SafehomesLibrary);
local modNpcProfileLibrary = shared.require(game.ReplicatedStorage.Library.NpcProfileLibrary);
local modStoragePresetLibrary = shared.require(game.ReplicatedStorage.Library.StoragePresetsLibrary);

local modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
local modAnalytics = shared.require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);

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
		--Debugger:StudioWarn("remoteSafehomeRequest", player, actionId, packet);
		
		local ownerPlayer = shared.modSafehomeService and shared.modSafehomeService.OwnerPlayer;
		local isOwner = ownerPlayer and player == ownerPlayer;
		
		if remoteSafehomeRequest:Debounce(player) then return {ReplyCode=3;} end;
		local profile = shared.modProfile:Get(player);
		if profile == nil then return {ReplyCode=5;} end;
		
		local traderProfile = profile.Trader;
		local safehomeData = profile.Safehome;
		
		
		if actionId == "fetch" then
			local oprofile = shared.modProfile:Get(ownerPlayer);

			if oprofile then
				return {ReplyCode=1; Data=oprofile.Safehome;};
			end
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
				modAnalytics.RecordResource(player.UserId, price, "Sink", "Gold", "Purchase", "Safehome_"..safehomeId);
				
				modAnalyticsService:Sink{
					Player=player;
					Currency=modAnalyticsService.Currency.Gold;
					Amount=price;
					EndBalance=traderProfile.Gold;
					ItemSKU=`Unlock:{safehomeId}`;
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

			local factionGroup = shared.modSafehomeService and shared.modSafehomeService.FactionGroupCache;
			
			if factionGroup then
				if factionGroup.HqHost ~= player.Name then
					shared.Notify(player, "Headquarters hosted by ".. factionGroup.HqHost ..", cannot set headquarters.", "Negative");
					return {ReplyCode=4;};
				end
				
			else
				if not isOwner then
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
				
			if modBranchConfigs.IsWorld("Safehome") then
				if shared.modSafehomeService then
					if shared.modSafehomeService.FactionTag == nil then
						shared.modSafehomeService.LoadMap(safehomeId);
						
					else
						shared.modSafehomeService.LoadHeadquarters(factionGroup);
						
					end
				end
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
			
			if modBranchConfigs.IsWorld("Safehome") and isOwner and workspace:GetAttribute("FactionHeadquarters") == nil then
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
			
			if modBranchConfigs.IsWorld("Safehome") and isOwner then
				local survivorNpcClass = shared.modNpcs.getByOwner(player, npcName);
				survivorNpcClass:TeleportHide();
			end
			
			return {ReplyCode=1; Data=safehomeData;};
		end
		
		if not modBranchConfigs.IsWorld("Safehome") then return end;
		--== Safehome only functions;
		
		if actionId == "inspectSafehome" then
			if not isOwner then
				shared.Notify(player, "This is not your safehome.", "Negative");
				return {ReplyCode=4;};
			end;
			
			local safehomeId = packet.SafehomeId;
			local safehomeLib = modSafehomesLibrary:Find(safehomeId);
			if safehomeLib == nil then return {ReplyCode=5;} end;
			
			if shared.modSafehomeService then
				if shared.modSafehomeService.FactionTag then
					return {ReplyCode=4;};
				end
				
				local inspectMode = true;
				
				safehomeId = safehomeLib.Id;
				
				if safehomeLib.Unlocked == true or safehomeData.Homes[safehomeId] ~= nil then
					inspectMode = nil;
				end;
			
				shared.modSafehomeService.LoadMap(safehomeId, inspectMode);
			end
			
		elseif actionId == "playSound" and safehomeData.ActiveId ~= "default" then
			local soundId = packet.SoundId;
			local interactObject = packet.Object;
			
			if soundId == nil or #soundId <= 0 then
				
				local soundList = {};
				for _, sound in pairs(audioModule:GetChildren()) do
					if sound.TimeLength > 59 then
						table.insert(soundList, sound.SoundId);
					end
				end
				
				soundId = soundList[math.random(1, #soundList)];
			end
			
			if soundId:match("rbxassetid") == nil then
				soundId = "rbxassetid://"..soundId;
			end
			
			local globalSound = workspace:FindFirstChild("GlobalSoundSystem");
			if globalSound == nil then
				globalSound = Instance.new("Sound");
			end
			globalSound.Name = "GlobalSoundSystem";
			globalSound.SoundGroup = game.SoundService:FindFirstChild("InstrumentMusic");
			globalSound.Looped = true;
			globalSound.Parent = workspace;
			
			isSoundPlaying = globalSound.Playing;
			if interactObject then
				globalSound.Volume = 0;
				
				if #soundSources <= 0 then
					for _, obj in pairs(interactObject:GetDescendants()) do
						if obj.Name == "_SoundSystem" then
							local new = Instance.new("Sound");
							new.Parent = obj;
							new.SoundGroup = game.SoundService:FindFirstChild("InstrumentMusic");
							new.RollOffMaxDistance = 64;
							new.RollOffMinDistance = 1;
							new.RollOffMode = Enum.RollOffMode.LinearSquare;
							new.Looped = true;
							
							local newReverb = script:WaitForChild("ReverbSoundEffect"):Clone();
							newReverb.Parent = new;
							
							table.insert(soundSources, new);
						end
					end
				end
				
				for a=1, #soundSources do
					soundSources[a].SoundId = soundId;
				end
				
				if isSoundPlaying then
					for a=1, #soundSources do
						soundSources[a]:Stop();
					end
				else
					for a=1, #soundSources do
						soundSources[a]:Play();
					end
				end
				
			else
				globalSound.Volume = 1;
				
				for a=1, #soundSources do
					soundSources[a]:Stop();
				end
			end
		
			globalSound.SoundId = soundId;
			if isSoundPlaying then
				globalSound:Stop();
			else
				globalSound:Play();
			end
			
		elseif actionId == "togglePartyLights" and safehomeData.ActiveId ~= "default" then
			local interactObject = packet.Object;
			if interactObject == nil then return end;
			
			if #lightSources <= 0 then
				local objectTag = interactObject:WaitForChild("Safehouse");
				local safehouse = objectTag.Value:GetDescendants();
				
				for a=1, #safehouse do
					if safehouse[a].Name == "_lightSource" then
						local lightTable = {Source=safehouse[a]; OriginalColor=safehouse[a].Color; LightObjects={}};
						local lights = safehouse[a]:GetDescendants();
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
				
				spawn(function()
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
						wait(1);
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
		Player=player;
		UpdateFoodSupply=function()end;
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

--[[
	SafehomeData:GetNpc(npcName: string)

	@param npcName Name of npc.
	@return npcData metatable is shared serverside 
]]
function SafehomeData:GetNpc(npcName: string)
	local npcLib = modNpcProfileLibrary:Find(npcName);
	if npcLib == nil then return end;

	local npcData = self.Npc[npcName];
	if npcData == nil then
		npcData = setmetatable({}, modNpcProfileLibrary:GetProperties(npcName));
		self.Npc[npcName] = npcData;

	else
		setmetatable(npcData, modNpcProfileLibrary:GetProperties(npcName));
	end
	
	local storageConfig = table.clone(npcData.StorageConfig);
	local storageId = `{npcName}Storage`;
	storageConfig.Name = `{npcName} Storage`;
	storageConfig.OwnerNpc = npcName;
	
	function storageConfig.InitStorage(storage)
		storage:ConnectCheck(function(packet)
			local dragStorageItem = packet.DragStorageItem;
			local targetIndex: number = packet.TargetIndex;
			
			if targetIndex == 1 then -- primary weapon slot;
				if modItemsLibrary:HasTag(dragStorageItem.ItemId, "Primary Weapon") then
					packet.Allowed = true;
				else
					packet.FailMsg = "This slot is only for primary weapons.";
					packet.Allowed = false;

				end
				
			elseif targetIndex == 2 then -- secondary weapon slot;
				if modItemsLibrary:HasTag(dragStorageItem.ItemId, "Secondary Weapon") then
					packet.Allowed = true;
				else
					packet.FailMsg = "This slot is only for secondary weapons.";
					packet.Allowed = false;

				end

			elseif targetIndex == 3 then -- melee weapon slot;
				if modItemsLibrary:HasTag(dragStorageItem.ItemId, "Melee") then
					packet.Allowed = true;
				else
					packet.FailMsg = "This slot is only for melee weapons.";
					packet.Allowed = false;

				end
				
			elseif targetIndex == 4 then -- clothing slot;
				if modItemsLibrary:HasTag(dragStorageItem.ItemId, "Clothing") then
					packet.Allowed = true;
				else
					packet.FailMsg = "This slot is only for melee weapons.";
					packet.Allowed = false;

				end

			elseif targetIndex == 5 then -- misc slot;
				packet.Allowed = true;

			else
				packet.Allowed = false;
			end
			
			return packet;
		end)

		storage.OnChanged:Connect(function()
			modOnGameEvents:Fire("OnStorageChanged", self.Player, storage);
			
			local npcClass = shared.modNpcs.getByOwner(self.Player, npcName);
			if npcClass then
				local storageItemIndexList = storage:GetIndexDictionary();

				local activeWeapon = storageItemIndexList[1] or storageItemIndexList[2];
				if activeWeapon then
					npcClass.Wield.Equip(activeWeapon.ItemId);
					npcClass.Wield.SetSkin(activeWeapon.Values);

					self.Wield.SetCustomization(activeWeapon.Values["_Customs"], activeWeapon.Values["ActiveSkin"]);
					npcClass.Wield:ToggleIdle();

				else
					npcClass.Wield.Unequip();

				end
			end
		end);
	end

	local storagePresetLib = modStoragePresetLibrary:Find("npcstorage");

	local storage = modStorage.openStorage(storageId, {
		Player = self.Player;
		
		StorageName = storageConfig.Name;
		StoragePresetLib = storagePresetLib;
	});
	npcData.GetStorage = function()
		return storage;
	end

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
	for npcName,_ in pairs(self.Npc) do
		if self.Npc[npcName].Active == nil then continue end;
		local npcData = self:GetNpc(npcName);

		if npcData.CalculateHappiness then
			npcData:CalculateHappiness();
		end
	end
end


return SafehomeData;
