local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local MakeshiftBuildable = super.newPackage{
		Name = "MakeshiftBuildable";
        Type = "ButtonRotd";
    };

    function MakeshiftBuildable.new(interactable: InteractableInstance)
        local config: Configuration = interactable.Config;
        local model = config.Parent;

        local buildObjects = {};
        interactable.Values.Builds = buildObjects;

        for _, obj in pairs(model:GetChildren()) do
            if obj.Name:sub(1, 6) ~= "Build_" then continue end;

            local nameSplit = obj.Name:split("_");

            table.insert(buildObjects, {
                Object = obj;
                MatName = nameSplit[2];
                Index = nameSplit[3] or #buildObjects;
            });
        end

        table.sort(buildObjects, function(a, b)
            return a.Index < b.Index;
        end)
        for a=1, #buildObjects do
            local obj = buildObjects[a].Object;

            if RunService:IsServer() then 
                local function updateModel()
                    local isBuildComplete = config:GetAttribute("Complete");
                    local isObjBuilt = obj:GetAttribute("Built");
                    
                    obj.Transparency = isObjBuilt and 0 or 1;
                    obj.CanCollide = isObjBuilt and isBuildComplete;

                    for _, c in ipairs(obj:GetChildren()) do
                        if not c:IsA("BasePart") then continue end;

                        local defCanCollide = c:GetAttribute("DefaultCanCollide");
                        if defCanCollide == nil then
                            c:SetAttribute("DefaultCanCollide", c.CanCollide);
                            defCanCollide = c.CanCollide;
                        end
                        if defCanCollide == true then
                            c.CanCollide = isObjBuilt and isBuildComplete;
                        end

                        if c.Name == "Hitbox" then continue end;

                        local defTransparency = c:GetAttribute("DefaultTransparency");
                        if defTransparency == nil then
                            c:SetAttribute("DefaultTransparency", c.Transparency);
                            defTransparency = c.Transparency;
                        end
                        c.Transparency = isObjBuilt and defTransparency or 1;
                    end
                end

                obj:GetAttributeChangedSignal("Built"):Connect(updateModel);
                obj:SetAttribute("Built", false);
                config:GetAttributeChangedSignal("Complete"):Connect(updateModel);
            end;
        end

    end

    function MakeshiftBuildable.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        MakeshiftBuildable.TypePackage.BindInteract(interactable, info);
        if info.Action == "Client" then return end;

        local config = interactable.Config;
        if config:GetAttribute("Complete") then
            return;
        end

        local player = info.Player;
        if player == nil then return; end

        local playerClass: PlayerClass = shared.modPlayers.get(player);
        local wieldComp = playerClass.WieldComp;

        if wieldComp.ItemId ~= "carryitem"
        or wieldComp.EquipmentClass == nil
        or wieldComp.EquipmentClass.Properties == nil
        or wieldComp.EquipmentClass.Properties.GenericType ~= "MakeshiftMaterial" then
            return;
        end

        local equipmentClass = wieldComp.EquipmentClass;
        local wieldProperties = equipmentClass.Properties;
        local matName = wieldProperties.MaterialName;

        local buildObjs = interactable.Values.Builds;

        local matchMats = {};
        for a=1, #buildObjs do
            if buildObjs[a].MatName ~= matName then continue end;
            if buildObjs[a].Object:GetAttribute("Built") then continue end;
            table.insert(matchMats, buildObjs[a]);
        end
        if #matchMats <= 0 then return end;

        local buildObj = matchMats[1];
        buildObj.Object:SetAttribute("Built", true);
        modAudio.Play("Repair", buildObj.Object);
            
        local interactModel = wieldProperties.InteractableModel;
        wieldProperties.InteractableModel = nil;
        Debugger.Expire(interactModel);

        wieldComp:Unequip();

        local isComplete = true;
        for a=1, #buildObjs do
            if buildObjs[a].Object:GetAttribute("Built") then continue end;
            isComplete = false;
            break;
        end

        if isComplete then
            config:SetAttribute("Complete", true);
            shared.modEventService:ServerInvoke(
                "Interactables_BindMakeshiftBuilt", 
                {ReplicateTo=game.Players:GetPlayers()},
                interactable,
                info
            );
        end

        return;
    end

    function MakeshiftBuildable.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        MakeshiftBuildable.TypePackage.BindPrompt(interactable, info);
        if info.Action == "Server" then return end;

        local player = info.Player;
        if player == nil then return; end

        local playerClass: PlayerClass = shared.modPlayers.get(player);
        local wieldComp = playerClass.WieldComp;

        local config = interactable.Config;
        local model = config.Parent;
        local interactPointAtt = config:FindFirstChild("IndicatorPoint");

        if config:GetAttribute("Complete") then
            local completeStr = config:GetAttribute("BuildCompleteLabel");
            if completeStr then
                interactable.Label = completeStr;
            end

            interactable.CanInteract = false;
            interactPointAtt.WorldPosition = model:GetPivot().Position;
            return;
        end

        if wieldComp.ItemId ~= "carryitem"
        or wieldComp.EquipmentClass == nil
        or wieldComp.EquipmentClass.Properties == nil
        or wieldComp.EquipmentClass.Properties.GenericType ~= "MakeshiftMaterial" then
            interactable.Label = `Hmm.. Needs makeshift materials, I should look around..`;
            interactable.CanInteract = false;
            interactPointAtt.WorldPosition = model:GetPivot().Position;
            return;
        end
        
        local wieldProperties = wieldComp.EquipmentClass.Properties;
        local matName = wieldProperties.MaterialName;

        local buildObjs = interactable.Values.Builds;

        local matchMats = {};
        for a=1, #buildObjs do
            if buildObjs[a].MatName ~= matName then continue end;
            table.insert(matchMats, buildObjs[a]);
        end

        if #matchMats <= 0 then
            interactable.Label = `This isn't compatible, {matName} is probably for something else..`;
            interactable.CanInteract = false;
            interactPointAtt.WorldPosition = model:GetPivot().Position;
            return;
        end

        local unbuiltObj = nil;
        for a=1, #matchMats do
            if matchMats[a].Object:GetAttribute("Built") then continue end;
            unbuiltObj = matchMats[a];
            break;
        end

        if unbuiltObj == nil then
            interactable.Label = `This material is no longer needed.. I should find something else..`;
            interactable.CanInteract = false;
            interactPointAtt.WorldPosition = model:GetPivot().Position;
            return;
        end

        interactable.Label = `Build`;
        interactable.CanInteract = true;
        interactPointAtt.WorldPosition = unbuiltObj.Object.Position;

        return;
    end

    function MakeshiftBuildable.BindDestroy(interactable: InteractableInstance)
        interactable.Values.Builds = nil;
    end

    super.registerPackage(MakeshiftBuildable);



    --MARK: MakeshiftMaterial
    local MakeshiftMaterial = super.newPackage{
		Name = "MakeshiftMaterial";
        Type = "ButtonRotd";
    };

    function MakeshiftMaterial.new(interactable: InteractableInstance)
        local config: Configuration = interactable.Config;
        local model = config.Parent;

        local handle = model:WaitForChild("Handle");
        if RunService:IsClient() then return end;
        
        handle.CustomPhysicalProperties = PhysicalProperties.new(10, 1, 0);

        local bv = Instance.new("BodyVelocity");
        bv.MaxForce = Vector3.new(10000, 1000, 10000);
        bv.Velocity = Vector3.zero;
        bv.Parent = handle;

        local newHighlight = Instance.new("Highlight");
        newHighlight.DepthMode = Enum.HighlightDepthMode.Occluded;
        newHighlight.FillTransparency = 1;
        newHighlight.OutlineTransparency = 0.5;
        newHighlight.Parent = model;
    end

    function MakeshiftMaterial.BindPrompt(interactable: InteractableInstance)
        interactable.Label = `Pick up {interactable.Values.MaterialName} makeshift material`;

    end

    function MakeshiftMaterial.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        MakeshiftMaterial.TypePackage.BindInteract(interactable, info);
        if info.Action == "Client" then return end;

        local player = info.Player;
        if player == nil then return; end

        local config: Configuration = interactable.Config;
        local model = config.Parent;
        local handle = model:WaitForChild("Handle");
        
        local matName = interactable.Values.MaterialName;

        local playerClass: PlayerClass = shared.modPlayers.get(player);
		playerClass.WieldComp:Equip{
			ItemId = "carryitem";
			ProxyEquip = true;
            ProxySiid = `w:{matName}`;
            ProxyEquipCallback = function(toolHandler: ToolHandlerInstance)
                local mainToolModel = toolHandler.MainToolModel;
                mainToolModel:SetAttribute("MaterialName", matName);
        
                local properties = toolHandler.EquipmentClass.Properties;
                properties.HandleTemplate = handle;
                
                properties.GenericType = "MakeshiftMaterial";
                properties.InteractableModel = model;

                -- local storageItem: StorageItem = toolHandler.StorageItem;
                -- storageItem:SetValues("MatName", matName);
            end
		};

        handle.Anchored = false;

        return;
    end

    super.registerPackage(MakeshiftMaterial);

end

return interactablePackage;

