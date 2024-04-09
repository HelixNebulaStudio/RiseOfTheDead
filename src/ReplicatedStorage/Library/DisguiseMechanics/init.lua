local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== 
local DisguiseMechanics = {};
DisguiseMechanics.__index = DisguiseMechanics;

local CollectionService = game:GetService("CollectionService");

local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local propDisguises = script:WaitForChild("PropDisguises");

DisguiseMechanics.Library = modLibraryManager.new();
DisguiseMechanics.Library:Add{
	Id="clear";
	Name="Remove Disguise";
	Type="Clear";
}

if modBranchConfigs.CurrentBranch.Name == "Dev" then
	DisguiseMechanics.Library:Add{
		Id="tom";
		Name="Tom";
		Type="Npc";
	}
end

DisguiseMechanics.Library:Add{
	Id="ch1";
	Name="Chair";
	Type="Prop";
}

DisguiseMechanics.Library:Add{
	Id="cr1";
	Name="Wooden Crate";
	Type="Prop";
}

DisguiseMechanics.Library:Add{
	Id="cr2";
	Name="Wooden Crate 2";
	Type="Prop";
}

DisguiseMechanics.Library:Add{
	Id="pl1";
	Name="Office Plant 1";
	Type="Prop";
}

DisguiseMechanics.Library:Add{
	Id="ba1";
	Name="Barral 1";
	Type="Prop";
}

DisguiseMechanics.Library:Add{
	Id="nic";
	Name="Nick";
	Type="Npc";
}

DisguiseMechanics.Library:Add{
	Id="ste";
	Name="Stephanie";
	Type="Npc";
}

DisguiseMechanics.Library:Add{
	Id="bc1";
	Name="Bloxy Cola";
	Type="Prop";
	Price=50;
}

DisguiseMechanics.Library:Add{
	Id="cr3";
	Name="Reward Crate";
	Type="Prop";
	Price=50;
}

DisguiseMechanics.Library:Add{
	Id="snowman";
	Name="Snowman";
	Type="Prop";
	Price=2500;
}

DisguiseMechanics.Library:Add{
	Id="tr1";
	Name="Trash Bags";
	Type="Prop";
	Price=50;
}

DisguiseMechanics.Library:Add{
	Id="pob1";
	Name="Pile of Boxes";
	Type="Prop";
	Price=50;
}

DisguiseMechanics.Library:Add{
	Id="sc1";
	Name="Supply Crate";
	Type="Prop";
	Price=50;
}

DisguiseMechanics.Library:Add{
	Id="ge1";
	Name="Generator";
	Type="Prop";
	Price=50;
}

DisguiseMechanics.Library:Add{
	Id="mas";
	Name="Mason";
	Type="Npc";
	Price=50;
}

DisguiseMechanics.Library:Add{
	Id="jes";
	Name="Jesse";
	Type="Npc";
	Price=50;
}

DisguiseMechanics.Library:Add{
	Id="man1";
	Name="Mannequin";
	Type="Prop";
	Price=200;
}

DisguiseMechanics.Library:Add{
	Id="sca1";
	Name="Scarecrow";
	Type="Prop";
	Price=200;
}

DisguiseMechanics.Library:Add{
	Id="mb1";
	Name="Metal Barricade";
	Type="Prop";
	Price=200;
}

DisguiseMechanics.Library:Add{
	Id="zo1";
	Name="Zombie";
	Type="Npc";
	RandomClothes=true;
	Price=200;
}

DisguiseMechanics.Library:Add{
	Id="pat";
	Name="Patrick";
	Type="Npc";
	Price=200;
}

DisguiseMechanics.Library:Add{
	Id="zo2";
	Name="Bandit Zombie";
	Type="Npc";
	Price=200;
}

DisguiseMechanics.Library:Add{
	Id="len";
	Name="Lennon";
	Type="Npc";
	Price=200;
}

DisguiseMechanics.Library:Add{
	Id="ali";
	Name="Alice";
	Type="Npc";
	Price=200;
}

DisguiseMechanics.Library:Add{
	Id="rus";
	Name="Russell";
	Type="Npc";
	Price=500;
}

DisguiseMechanics.Library:Add{
	Id="mic";
	Name="Michael";
	Type="Npc";
	Price=500;
}

DisguiseMechanics.Library:Add{
	Id="jan";
	Name="Jane";
	Type="Npc";
	Price=500;
}

DisguiseMechanics.Library:Add{
	Id="car";
	Name="Carlos";
	Type="Npc";
	Price=500;
}

DisguiseMechanics.Library:Add{
	Id="jos";
	Name="Joseph";
	Type="Npc";
	Price=500;
}

DisguiseMechanics.Library:Add{
	Id="hil";
	Name="Hilbert";
	Type="Npc";
	Price=1000;
}

DisguiseMechanics.Library:Add{
	Id="cul";
	Name="Cultist";
	Type="Npc";
	Price=1000;
}

DisguiseMechanics.Library:Add{
	Id="kly";
	Name="Klyde";
	Type="Npc";
	Price=1000;
}

DisguiseMechanics.Library:Add{
	Id="kar";
	Name="Karl";
	Type="Npc";
	Price=2000;
}

DisguiseMechanics.Library:Add{
	Id="sha";
	Name="Shadow";
	Type="Npc";
	Price=2000;
}

DisguiseMechanics.Library:Add{
	Id="hs1";
	Name="Hector Shot";
	Type="Npc";
	Price=2000;
}

DisguiseMechanics.Library:Add{
	Id="vm1";
	Name="Vending Machine";
	Type="Prop";
	Price=5000;
}

DisguiseMechanics.Library:Add{
	Id="jef";
	Name="Jefferson";
	Type="Npc";
	Price=5000;
}

DisguiseMechanics.Library:Add{
	Id="zar";
	Name="Zark";
	Type="Npc";
	Price=5000;
}

DisguiseMechanics.Library:Add{
	Id="eugene";
	Name="Eugene";
	Type="Npc";
	Price=5000;
}

DisguiseMechanics.Library:Add{
	Id="revas";
	Name="Revas";
	Type="Npc";
	Price=5000;
}

--==
function weldAttachments(attach1, attach2)
	local weld = Instance.new("Weld")
	weld.Name = "Attachment";
	weld.Part0 = attach1.Parent
	weld.Part1 = attach2.Parent
	weld.C0 = attach1.CFrame
	weld.C1 = attach2.CFrame
	weld.Parent = attach2.Parent
	return weld
end

local function findFirstMatchingAttachment(model, name)
	for _, child in pairs(model:GetChildren()) do
		if child:IsA("Attachment") and child.Name == name then
			return child
		elseif not child:IsA("Accoutrement") and not child:IsA("Tool") then
			local foundAttachment = findFirstMatchingAttachment(child, name)
			if foundAttachment then
				return foundAttachment
			end
		end
	end
end

function DisguiseMechanics:Disguise(player, disguiseId, expireTime)
	local classPlayer = modPlayers.GetByName(player.Name);
	local character = classPlayer.Character;
	local disguiseLib = DisguiseMechanics.Library:Find(disguiseId);
	
	if classPlayer == nil or disguiseLib == nil then return end;
	
	if classPlayer.Properties["Disguised"] then
		-- Clear old disguise;
		for _, obj in pairs(classPlayer.Character:GetDescendants()) do
			if obj.Name == "InvisibleValue" then
				obj:Destroy();
			end
		end
		
		for _, obj in pairs(classPlayer.Character:GetChildren()) do
			if obj.Name == "DisguiseModel" then
				obj:Destroy();
			end
		end
		
		if character:FindFirstChild("Copy") then
			for _, obj in pairs(character.Copy:GetChildren()) do
				obj.Parent = character;
			end
			character.Copy:Destroy();
		end
		
	end
	
	classPlayer:SetProperties("Disguised", nil);
	wait(0.1);
	if disguiseLib.Type == "Clear" then
		return;
	end;
	
	local statusInvisiblity = disguiseLib.Type == "Prop";
	
	if disguiseLib.Type == "Prop" then
		local prefab = propDisguises:FindFirstChild(disguiseId) and propDisguises[disguiseId]:Clone();
		if prefab then
			prefab.Name = "DisguiseModel";
			prefab.Parent = character;
			
			local joint = Instance.new("Motor6D");
			joint.Parent = prefab:WaitForChild("Base");
			joint.Part0 = classPlayer.RootPart;
			joint.Part1 = prefab:WaitForChild("Base");
			joint.C0 = CFrame.new(0, -2.4, 0);
			
			for _, obj in pairs(prefab:GetDescendants()) do
				if obj:IsA("BasePart") then
					CollectionService:AddTag(obj, "DisguiseObject");
				end
			end

			local accessoriesTag = prefab:FindFirstChild("AccessoriesTag");
			if accessoriesTag then
				local appearance = player:FindFirstChild("Appearance");
				local head = prefab:FindFirstChild("Head");
				
				if appearance and head then
					for _, accessory in pairs(appearance:GetChildren()) do
						local attachment = accessory:FindFirstChildWhichIsA("Attachment", true);

						if attachment and head:FindFirstChild(attachment.Name) then
							local new = accessory:Clone();
							new.Parent = prefab;
							
							local accessoryAttachment = new:FindFirstChildWhichIsA("Attachment", true);
							local characterAttachment = prefab:FindFirstChild(accessoryAttachment.Name, true);
							
							weldAttachments(characterAttachment, accessoryAttachment);
						end
					end
				end
			end
		end
		
	elseif disguiseLib.Type == "Npc" then
		local npcPrefabs = game.ServerStorage.PrefabStorage.Npc;
		local new = npcPrefabs:FindFirstChild(disguiseLib.Name) and npcPrefabs[disguiseLib.Name]:Clone();
		if new then
			local function setInvisValue(obj, v)
				obj:SetAttribute("InvisibleValue", v);
			end
			
			local copy = Instance.new("Folder");
			copy.Name = "Copy";
			copy.Parent = character;
			
			if character:FindFirstChild("Shirt") then
				character.Shirt.Parent = copy;
			end
			if character:FindFirstChild("Pants") then
				character.Pants.Parent = copy;
			end
			if character:FindFirstChild("Body Colors") then
				character["Body Colors"].Parent = copy;
			end
			if character.Head:FindFirstChild("face") then
				setInvisValue(character.Head.face, 0);
				
				if new:FindFirstChild("Head") and new.Head:FindFirstChild("face") then
					character.Head.face.Texture = new.Head.face.Texture;
				end
			end
			
			for _, obj in pairs(new:GetChildren()) do
				if obj:IsA("BasePart") then
					if character:FindFirstChild(obj.Name) then
						local charPart = character[obj.Name];
						charPart.Color = obj.Color;
						charPart.Material = obj.Material;
						setInvisValue(charPart, obj.Transparency);
					end
				
				elseif obj:IsA("Accessory") or obj:IsA("Shirt") or obj:IsA("Pants") then
					obj.Parent = character;
					obj.Name = "DisguiseModel";
				end
			end
			
			if disguiseLib.RandomClothes then
				local modClothing = require(game.ServerScriptService.ServerLibrary.Clothing);
				local shirt = modClothing:GetRandomShirt();
				shirt.Name = "DisguiseModel";
				shirt.Parent = character;
				
				local pants = modClothing:GetRandomPants();
				pants.Name = "DisguiseModel";
				pants.Parent = character;
			end
			
			new:Destroy();
		end
	end
	
	local packet = {Name=disguiseLib.Name; Invisible=statusInvisiblity;};
	
	if expireTime then
		packet.ExpiresOnDeath=true;
		packet.Expires=modSyncTime.GetTime()+expireTime;
		packet.Duration=expireTime;
		packet.OnExpire=function()
			DisguiseMechanics:Disguise(player, "clear");
		end;
	end
	
	if modBranchConfigs.CurrentBranch.Name == "Dev" then
		packet.Visible = false;
	end
	
	classPlayer:SetProperties("Disguised", packet);
end

return DisguiseMechanics;
