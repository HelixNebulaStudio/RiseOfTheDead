local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);

local ClientNpcComponent = {
    RemoteHandlers = {};
};

ClientNpcComponent.RemoteHandlers["threatsense"] = function(...)
    local character = ...;
    if character == nil or character:GetAttribute("Invisible") == true or character:HasTag("Deadbody") then return end;
    
    local thrsenHighlight = character:FindFirstChild("thrsenHighlight") :: Highlight;
    if thrsenHighlight then
        local spawnTime = thrsenHighlight:GetAttribute("SpawnTime");
        if spawnTime == nil or tick()-spawnTime >9 then
            thrsenHighlight:Destroy();
        else
            return;
        end
    end;
    
    thrsenHighlight = Instance.new("Highlight");
    thrsenHighlight.Name = "thrsenHighlight";
    thrsenHighlight:SetAttribute("SpawnTime", tick());
    
    if modGlobalVars.IsMobile() then
        thrsenHighlight.FillTransparency = 0.8;
        thrsenHighlight.FillColor = Color3.fromRGB(255,80,80);
        thrsenHighlight.OutlineTransparency = 1;
        
    else
        thrsenHighlight.FillTransparency = 1;
        thrsenHighlight.FillColor = Color3.fromRGB(255,80,80);
        thrsenHighlight.OutlineTransparency = 0.65;
        thrsenHighlight.OutlineColor = Color3.fromRGB(255,80,80);
        
    end
    
    thrsenHighlight.Parent = character;
    Debugger.Expire(thrsenHighlight, 10);
end

return ClientNpcComponent;