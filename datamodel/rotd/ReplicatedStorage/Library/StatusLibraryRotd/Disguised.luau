local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);

local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local localPlayer = game.Players.LocalPlayer;

local modDisguiseMechanics = shared.require(game.ReplicatedStorage.Library.DisguiseMechanics);

if RunService:IsServer() then
    modNpcClothing = shared.require(game.ServerScriptService.ServerLibrary.NpcClothing);
end

--==
local statusPackage = {
    Id = "Disguised";
    Icon = "rbxassetid://5783987908";
    Name = "Disguised";
    Description = "You are disguised as $Name.";
    Buff = true;
    ExpiresOnDeath = true;
};


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

function statusPackage.onRequire()
    if RunService:IsClient() then
        CollectionService:GetInstanceAddedSignal("DisguiseObject"):Connect(function(object)
            if localPlayer.Character == nil then return end;
            if not localPlayer.Character:IsAncestorOf(object) then return end;

            object.CanCollide = true;
        end)
    end
end

function statusPackage.BindApply(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;
    statusPackage.BindUpdate(statusClass);
end

function statusPackage.BindUpdate(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;
    if statusClass.StatusOwner.ClassName ~= "PlayerClass" then return end;

    local playerClass: PlayerClass = statusClass.StatusOwner :: PlayerClass;
    local player: Player = playerClass:GetInstance();

    local character = playerClass.Character;
    local disguiseId = statusClass.Values.DisguiseId;
	local disguiseLib = modDisguiseMechanics.Library:Find(disguiseId);
	if disguiseLib == nil then return end;

	if disguiseLib.Type == "Clear" then
		statusClass.IsExpired = true;
		return;
	end;

	local statusInvisiblity = disguiseLib.Type == "Prop";
    statusClass.Values.Invisible = statusInvisiblity;
    statusClass.Values.Name = disguiseLib.Name;

    -- Clear prev
    local function clear()
        for _, obj in pairs(character:GetDescendants()) do
            if obj:GetAttribute("InvisibleValue") ~= nil then
                obj:SetAttribute("InvisibleValue", nil)
            end
        end
        for _, obj in pairs(character:GetChildren()) do
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
    clear();
    statusClass.Garbage:Tag(clear);

	if disguiseLib.Type == "Prop" then
        local propDisguises = modDisguiseMechanics.Props;
		local prefab = propDisguises:FindFirstChild(disguiseId) and propDisguises[disguiseId]:Clone();
		if prefab == nil then return end;

        prefab.Name = "DisguiseModel";
        prefab.Parent = character;
        
        local joint = Instance.new("Motor6D");
        joint.Parent = prefab:WaitForChild("Base");
        joint.Part0 = playerClass.RootPart;
        joint.Part1 = prefab:WaitForChild("Base");
        joint.C0 = disguiseLib.C0Offset or CFrame.new(0, -2.4, 0);
        
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
		
	elseif disguiseLib.Type == "Npc" then

		local npcPrefab = shared.modNpcs.getNpcPrefab(disguiseLib.Name);
		local newChar = npcPrefab and npcPrefab:Clone();
		if newChar == nil then return end;

        if disguiseLib.CustomBody == true then
            statusClass.Values.Invisible = true;
            newChar.Parent = character;
            newChar.Name = "DisguiseModel";

            newChar:PivotTo(character:GetPivot());

            local primaryPart = newChar:WaitForChild("HumanoidRootPart");
            primaryPart.Massless = true;

            local joint = Instance.new("Motor6D");
            joint.Parent = primaryPart;
            joint.Part0 = playerClass.RootPart;
            joint.Part1 = primaryPart;
            joint.C0 = disguiseLib.C0Offset or CFrame.new(0, 0.6, 0);

            for _, obj in pairs(newChar:GetDescendants()) do
                if obj:IsA("BasePart") then
                    obj.Massless = true;
                    obj.CanCollide = false;
                    obj.CanQuery = false;
                end
            end

            local humanoid = newChar:FindFirstChildWhichIsA("Humanoid");
            if humanoid then
                humanoid.Name = "Disguise";
                humanoid.EvaluateStateMachine = false;
                humanoid.NameDisplayDistance = 0;
                humanoid.HealthDisplayDistance = 0;

                local animator = character:WaitForChild("Humanoid"):WaitForChild("Animator");
                local newAnimator = humanoid:WaitForChild("Animator") :: Animator;

                for _, animationTrack: AnimationTrack in pairs(animator:GetPlayingAnimationTracks()) do
                    local newAnimTrack: AnimationTrack = newAnimator:LoadAnimation(animationTrack.Animation) :: AnimationTrack;
                    newAnimTrack:Play();

                    animationTrack.Stopped:Connect(function()
                        newAnimTrack:Stop();
                    end);
                end

                local animPlayCon = animator.AnimationPlayed:Connect(function(animationTrack: AnimationTrack)
                    pcall(function()
                        local newAnimTrack = newAnimator:LoadAnimation(animationTrack.Animation) :: AnimationTrack;
                        newAnimTrack:Play();

                        animationTrack.Stopped:Connect(function()
                            newAnimTrack:Stop();
                        end);
                    end)
                end);

                newChar.Destroying:Once(function()
                    if animPlayCon then
                        animPlayCon:Disconnect();
                    end
                end)

            end

        else
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
                
                if newChar:FindFirstChild("Head") and newChar.Head:FindFirstChild("face") then
                    character.Head.face.Texture = newChar.Head.face.Texture;
                end
            end

            for _, obj in pairs(newChar:GetChildren()) do
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
                local presetShirt = modNpcClothing:GetShirt(newChar.Name, math.random(1111, 9999));
                local shirt = Instance.new("Shirt");
                shirt.ShirtTemplate = presetShirt.Id;
                shirt.Name = "DisguiseModel";
                shirt.Parent = character;
                
                local presetPants = modNpcClothing:GetPants(newChar.Name, math.random(1111, 9999));
                local pants = Instance.new("Pants");
                pants.PantsTemplate = presetPants.Id;
                pants.Name = "DisguiseModel";
                pants.Parent = character;
            end
            
            newChar:Destroy();
        end
	end
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;
    if statusClass.StatusOwner.ClassName ~= "PlayerClass" then return end;

    local playerClass: PlayerClass = statusClass.StatusOwner :: PlayerClass;
    local player: Player = playerClass:GetInstance();
end


return modStatusClass.new(statusPackage);