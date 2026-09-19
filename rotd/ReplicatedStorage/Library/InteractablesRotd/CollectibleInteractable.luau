local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modTableManager = shared.require(game.ReplicatedStorage.Library.TableManager);
local modCollectiblesLibrary = shared.require(game.ReplicatedStorage.Library.CollectiblesLibrary);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

local interactablePackage = {};
--==
function interactablePackage.init(super) -- Server/Client
    local Collectible = super.newPackage{
		Name = "Collectible";
        Type = "Button";
    };
    
    function Collectible.new(interactable: InteractableInstance, player: Player)
        if not RunService:IsClient() then return end;
    end
    
    function Collectible.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if RunService:IsClient() then
            modAudio.Preload("Collectible", 5);
			modAudio.Play("Collectible", nil, nil, false);
        end

        Collectible.TypePackage.BindInteract(interactable, info);

        -- MARK: Server side
        if info.Action == "Client" then return end;

        local player = info.Player;
        if player == nil then return end;

        local id = interactable.Id;

		local collectibleLib = modCollectiblesLibrary:Find(id);
		if collectibleLib == nil then return; end;
        
		shared.modEventService:ServerInvoke(
            "Interactables_BindCollectibleInteract", 
            {ReplicateTo={player}}, 
            interactable
        );

        local profile = shared.modProfile:Get(player);
		profile:UnlockCollectible(id);

        modReplicationManager.UnreplicateFrom(player, interactable.Part);
    end

    function Collectible.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        if not RunService:IsClient() then return end;
        
        local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
        local collectiblesData = modTableManager.GetDataHierarchy(modData.Profile, "Collectibles");
        
        local id = interactable.Id;
        
        if collectiblesData == nil or collectiblesData[id] == nil then return end;
        Debugger.Expire(interactable.Part, 0);
    end

    super.registerPackage(Collectible);

end

return interactablePackage;

