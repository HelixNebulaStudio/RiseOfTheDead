local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local ClientNpcComponent = {
    RemoteHandlers = {};
};

ClientNpcComponent.RemoteHandlers["detonate"] = function(...)
    local effectMesh, tweenTime, range = ...;

    if not workspace:IsAncestorOf(effectMesh) then return end; -- Probably not streamed in.
    local newEffect = effectMesh.Parent;

    local duration = tweenTime +0.3;
    TweenService:Create(effectMesh, 
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
        {Scale = Vector3.new(range,range,range)}
    ):Play();
    duration = duration-0.1;
    TweenService:Create(newEffect, 
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
        {Transparency = 1}
    ):Play();
end

return ClientNpcComponent;