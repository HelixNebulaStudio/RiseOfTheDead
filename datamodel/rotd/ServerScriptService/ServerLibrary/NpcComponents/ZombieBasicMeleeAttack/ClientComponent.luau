local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);

local ClientNpcComponent = {
    Remote = nil;
    RemoteHandlers = {};
};

ClientNpcComponent.RemoteHandlers["attack"] = function(...)
    local hitIndex, hitCf, hitSize, tarPart = ...;
    if not workspace:IsAncestorOf(tarPart) then return end;

    local isInMeleeHitbox = modVector.IsInBoundingBox(hitCf, hitSize, tarPart.Position);
    ClientNpcComponent.Remote:FireServer(script.Name, hitIndex, isInMeleeHitbox);
end

return ClientNpcComponent;