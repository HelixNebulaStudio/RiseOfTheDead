local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Script;
local CharacterAppearance = {};
CharacterAppearance.__index = CharacterAppearance;

local InsertService = game:GetService("InsertService");

local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modAppearanceLibrary = require(game.ReplicatedStorage.Library.AppearanceLibrary);
local modCustomizeAppearance = require(game.ReplicatedStorage.Library.CustomizeAppearance);
local modPrefabManager = require(game.ServerScriptService.ServerLibrary.PrefabManager);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modFacesLibrary = require(game.ReplicatedStorage.Library.FacesLibrary);
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modSettings = Debugger:Require(game.ReplicatedStorage.Library.Settings);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local starterCharacter = game.StarterPlayer:WaitForChild("StarterCharacter");
local cosmeticsPrefabs = game.ServerStorage:WaitForChild("PrefabStorage"):WaitForChild("Cosmetics");
local cosmeticsPrefabsList = cosmeticsPrefabs:GetDescendants();

local remoteSetPlayerFace = modRemotesManager:Get("SetPlayerFace");
local remoteToggleDefaultAccessories = modRemotesManager:Get("ToggleDefaultAccessories");

local isDevBranch = modBranchConfigs.CurrentBranch.Name == "Dev"
--==
for _, part in pairs(starterCharacter:GetChildren()) do
	if part:IsA("BasePart") then
		part.CollisionGroup = "Players";
	end
end

for a=1, #cosmeticsPrefabsList do 
	if cosmeticsPrefabsList[a]:IsA("BasePart") then cosmeticsPrefabsList[a].CollisionGroup = "Accessories"; end
end;

function CharacterAppearance.new(player)
	local self = {};
	self.Player = player;
	self.LastLoad = nil;
	
	setmetatable(self, CharacterAppearance);
	return self;
end

function CharacterAppearance:LoadAppearance(character)
	Debugger:Log("Load player appearance.", character);
	
	local userId = self.Player.userId > 0 and self.Player.userId or modGlobalVars.UseRandomId();
	
	local apprearanceFolder = Instance.new("Folder");
	apprearanceFolder.Name = "Appearance";
	
	local accessories = {};
	
	local s, e = pcall(function()
		local appearInfo = self.AppearInfo;
		if appearInfo == nil or self.LastLoad == nil or tick()-self.LastLoad > 60 then
			self.LastLoad = tick();
			
			appearInfo = game.Players:GetCharacterAppearanceInfoAsync(userId);
		end;
		
		if appearInfo == nil then return end;
		if appearInfo.bodyColors then
			local newBodyColors: BodyColors = Instance.new("BodyColors");
			
			if typeof(appearInfo.bodyColors.headColorId) == "number" then
				newBodyColors.HeadColor = BrickColor.new(appearInfo.bodyColors.headColorId);
				newBodyColors.TorsoColor = BrickColor.new(appearInfo.bodyColors.torsoColorId);
				newBodyColors.LeftArmColor = BrickColor.new(appearInfo.bodyColors.leftArmColorId);
				newBodyColors.RightArmColor = BrickColor.new(appearInfo.bodyColors.rightArmColorId);
				newBodyColors.LeftLegColor = BrickColor.new(appearInfo.bodyColors.leftLegColorId);
				newBodyColors.RightLegColor = BrickColor.new(appearInfo.bodyColors.rightLegColorId);
				
			else
				newBodyColors.HeadColor = appearInfo.bodyColors.headColorId;
				newBodyColors.TorsoColor = appearInfo.bodyColors.torsoColorId;
				newBodyColors.LeftArmColor = appearInfo.bodyColors.leftArmColorId;
				newBodyColors.RightArmColor = appearInfo.bodyColors.rightArmColorId;
				newBodyColors.LeftLegColor = appearInfo.bodyColors.leftLegColorId;
				newBodyColors.RightLegColor = appearInfo.bodyColors.rightLegColorId;
				
			end
			
			newBodyColors.Parent = apprearanceFolder;
		end
		
		local assetWhitelist = {
			["Shirt"]=1;
			["Pants"]=1;
			["Face"]=1;
			
			["Hat"]=2;
			["HairAccessory"]=2;
			["NeckAccessory"]=2;
			["FaceAccessory"]=2;
			["ShoulderAccessory"]=2;
			["FrontAccessory"]=2;
			["WaistAccessory"]=2;
			
			--["JacketAccessory"]=2;
			--["SweaterAccessory"]=2;
			--["ShortsAccessory"]=2;
			--["LeftShoeAccessory"]=2;
			--["RightShoeAccessory"]=2;
			--["DressSkirtAccessory"]=2;
			
			--["LeftArm"]=isDevBranch and 2 or nil;
			--["LeftLeg"]=isDevBranch and 2 or nil;
			--["RightArm"]=isDevBranch and 2 or nil;
			--["RightLeg"]=isDevBranch and 2 or nil;
			--["Torso"]=isDevBranch and 2 or nil;
			
			["IdleAnimation"]=3;
			["RunAnimation"]=3;
			["WalkAnimation"]=3;
			["ClimbAnimation"]=3;
			["FallAnimation"]=3;
			["JumpAnimation"]=3;
			["SwimAnimation"]=3;
		}
		
		if appearInfo.assets then
			for a=1, #appearInfo.assets do
				local asset = appearInfo.assets[a];
				local assetType = tostring(asset.assetType.name);
				
				if assetWhitelist[assetType] ~= nil then
					local loadPrefab; pcall(function() loadPrefab = InsertService:LoadAsset(asset.id); end)
					
					if loadPrefab then
						local modelChildren = loadPrefab:GetChildren();
						for _, obj in pairs(modelChildren) do
							for _, c in pairs(obj:GetDescendants()) do
								if c:IsA("BasePart") then
									c.CollisionGroup = "Accessories";
									c.CanCollide = false;
								elseif c:IsA("Sparkles") or c:IsA("ParticleEmitter") or c:IsA("Smoke") or c:IsA("Fire") then
									c:Destroy();
								end
							end
							
							if assetWhitelist[assetType] == 2 then
								obj.Name = asset.name;
								local assetId = tostring(asset.id);
								obj:SetAttribute("AssetId", assetId);
								accessories[assetId] = obj;
							end
							obj.Parent = apprearanceFolder;
						end
						loadPrefab:Destroy();
					end
				end
			end
		end
		
	end)
	
	if not s then Debugger:Warn(e) end;
	
	for _, obj in pairs(self.Player:GetChildren()) do
		if obj:IsA("Folder") and obj.Name == "Appearance" then
			game.Debris:AddItem(obj, 0);
		end
	end
	
	apprearanceFolder.Parent = self.Player;
	self.Folder = apprearanceFolder;
	
	if character == nil then Debugger:Log("Skip load equipped clothing, nil character") return end;
	
	local profile = modProfile:Get(self.Player);
	if profile then
		local activeSave = profile:GetActiveSave();
		if activeSave then
			local equippedAccessory = activeSave.AppearanceData;
			equippedAccessory:Update(activeSave.Clothing);
			
		else
			Debugger:Warn("Missing active save ", activeSave);
		end
		
		if profile.Settings.ToggleClothing == nil then
			profile.Settings.ToggleClothing = {};
		end
		local clothingToggleSettings = profile.Settings.ToggleClothing;
		
		for assetId, value in pairs(clothingToggleSettings) do
			local prefab = accessories[tostring(assetId)];
			
			if prefab then
				for _, obj in pairs(prefab:GetChildren()) do
					if obj:IsA("BasePart") then
						obj:SetAttribute("ToggleClothing", value); -- default clothing
						obj.Transparency = value and 0 or 1;
					end
				end
			else
				clothingToggleSettings[assetId] = nil;
			end
		end
		
	else
		Debugger:Warn("Could not load profile of "..self.Player.Name..".");
	end
end

function OnPlayerAdded(player)
	local charAppear = CharacterAppearance.new(player);
	
	task.spawn(function()
		charAppear:LoadAppearance();
	end)

	local profile = modProfile:Get(player);
	local activeSave = profile and profile:GetActiveSave();
	local equippedAccessory = activeSave and activeSave.AppearanceData
	if equippedAccessory then
		activeSave.AppearanceData:Update(activeSave.Clothing);
	end
	
	local function characterAdded(character)
		charAppear:LoadAppearance(character);

		local characterApperance = charAppear.Folder:GetChildren();

		local head = character:WaitForChild("Head");
		local newFace;
		for a=1, #characterApperance do
			if characterApperance[a].Name == "face" then
				local faceDecal = head:FindFirstChild("face");
				if faceDecal then
					faceDecal.Texture = characterApperance[a].Texture;
					newFace = faceDecal;
				end
			else
				player:LoadCharacterAppearance(characterApperance[a]:Clone());
			end
		end
		if newFace == nil then
			newFace = script.face:Clone();
			newFace.Parent = head;
		end

		local humanoid = character:WaitForChild("Humanoid");
		local rootPart = character:WaitForChild("HumanoidRootPart");
		local lowerTorso = character:WaitForChild("LowerTorso");
		
		local torsoParts = {"UpperTorso"; "LeftUpperArm"; "RightUpperArm"};
		local legsParts = {"LeftUpperLeg"; "RightUpperLeg"};
		
		local greymanShirt, greymanPants = false, false;
		local bodyObjects = character:GetChildren();
		for a=1, #bodyObjects do
			if bodyObjects[a]:IsA("BasePart") then
				bodyObjects[a].CollisionGroup = "Players";
				
			elseif bodyObjects[a]:IsA("Shirt") then
				if bodyObjects[a].ShirtTemplate == "http://www.roblox.com/asset/?id=8372408891" then
					greymanShirt = true;
				end
				
				--for _, bodypartName in pairs(torsoParts) do
				--	local part = character:FindFirstChild(bodypartName);
				--	if part then
				--		part.TextureID = bodyObjects[a].ShirtTemplate;
				--	end
				--end
				
			elseif bodyObjects[a]:IsA("Pants") then
				if bodyObjects[a].PantsTemplate == "http://www.roblox.com/asset/?id=8372421647" then
					greymanPants = true;
				end
				
				--for _, bodypartName in pairs(legsParts) do
				--	local part = character:FindFirstChild(bodypartName);
				--	if part then
				--		part.TextureID = bodyObjects[a].PantsTemplate;
				--	end
				--end
			end
		end
		
		if greymanShirt and greymanPants then
			newFace.Texture = "";
		end

		local equippedAccessory = activeSave and activeSave.AppearanceData
		if equippedAccessory then
			activeSave.AppearanceData:Update(activeSave.Clothing);
		end

		local classPlayer = shared.modPlayers.Get(player);
		classPlayer:OnNotIsAlive(function(character)
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None;
			
			--rootPart:Destroy();
			--local bodyObjects = character:GetChildren();
			--for a=1, #bodyObjects do
			--	if bodyObjects[a]:IsA("BasePart") then
			--		bodyObjects[a].CollisionGroup = "Debris";
					
			--		if bodyObjects[a].Name ~= "Head" then
			--			game.Debris:AddItem(bodyObjects[a], 6);
			--		end
			--	end
			--end
			
			if equippedAccessory then equippedAccessory.Equipped = {}; end;
		end)
		
	end
	
	if not player:IsDescendantOf(game.Players) then return end;
	
	player.CharacterAdded:Connect(characterAdded)
	if player.Character then
		characterAdded(player.Character);
	end
end

function CharacterAppearance.Init()

	local modEngineCore = require(game.ReplicatedStorage.EngineCore);
	modEngineCore:ConnectOnPlayerAdded(script, OnPlayerAdded);
end

remoteSetPlayerFace.OnServerEvent:Connect(function(player, id, value)
	if id == "ragdollEmote" then
		local classPlayer = modPlayers.Get(player);
		if value == 2 then
			classPlayer:SetProperties("Ragdoll", 2);
		else
			classPlayer:SetProperties("Ragdoll", 0);
		end
		return;
	end
	
	if remoteSetPlayerFace:Debounce(player) then return end;

	local classPlayer = modPlayers.Get(player);
	if classPlayer == nil or classPlayer.Head == nil then return end

	local face = classPlayer.Head:FindFirstChild("face");
	if face == nil then return end

	if face:GetAttribute("Default") == nil then
		face:SetAttribute("Default", face.Texture);
	end
	
	if id == nil then
		face.Texture = face:GetAttribute("Default");
		
	else
		local faceInfo = modFacesLibrary:Find(id);
		if faceInfo then
			face.Texture = faceInfo.Texture;
			
		else
			face.Texture = face:GetAttribute("Default");
			
		end
		
	end
end)

function remoteToggleDefaultAccessories.OnServerInvoke(player, assetId, value)
	local profile = shared.modProfile:Get(player);
	local classPlayer = modPlayers.Get(player);
	
	if profile == nil then return end;
	if classPlayer == nil then return end;
	
	local clothingToggleSettings = profile.Settings.ToggleClothing;
	
	local found = false;
	local character = classPlayer.Character;
	
	for _, obj in pairs(character:GetChildren()) do
		if obj:GetAttribute("AssetId") == assetId then
			found = true;
			
			if value == false then
				clothingToggleSettings[assetId] = false;
			else
				clothingToggleSettings[assetId] = nil;
			end
			
			value = clothingToggleSettings[assetId];
			
			for _, c in pairs(obj:GetChildren()) do
				if c:IsA("BasePart") then
					c:SetAttribute("ToggleClothing", value);
					c.Transparency = value == false and 1 or 0;
				end
			end
			
			break;
		end
	end
	
	profile.Settings.ToggleClothing = modSettings.Fix(player, "ToggleClothing", clothingToggleSettings);
end

return CharacterAppearance;
