local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

return function(event: EventPacket, ...)
    local config: Configuration, values: anydict = ...;
    
    local interactable: InteractableInstance = modInteractables.getOrNew(config, event.Player);
    if interactable == nil then return end

    Debugger:Warn(`BioXResearchButton`, values);
    modAudio.Play("PartyPopper", interactable.Object);
end;