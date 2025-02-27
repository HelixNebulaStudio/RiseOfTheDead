local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);

--local remoteInteract = modRemotesManager:Get("Interact");
--==
local InteractableHandler = {};
InteractableHandler.__index = InteractableHandler;

function InteractableHandler.init(super) -- Server/Client

    function super.HandlerName(src: ModuleScript, prefab)
		local newInteractable = super.new();
		newInteractable.Script = src;
		newInteractable.Prefab = prefab;

		local metaInteractable = getmetatable(newInteractable);
		metaInteractable.Label = "Interact";

		newInteractable.Type = "InteractType";
		newInteractable.IndicatorPresist = false;
		newInteractable.Label = nil;

		newInteractable.InteractDuration = 2;

		function newInteractable:OnInteracted(library)
		end

		function newInteractable:OnTrigger()
		end

		return newInteractable;
    end
end

return InteractableHandler;
