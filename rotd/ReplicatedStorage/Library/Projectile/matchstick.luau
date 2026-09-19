local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		Velocity = 100;
		Bounce = 0;
		LifeTime = 4;
		Acceleration = Vector3.new(0, -workspace.Gravity, 0);
		KeepAcceleration = true;
		Delta = 1/60;
	};

	Properties = {
		Damage = 100;
	};
};
--==

function projectilePackage.BindInstance(projectile: ProjectileInstance)
	projectile.Part = script:WaitForChild("MatchStick"):Clone();
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
    local hitPart = arcPoint.Hit;
    if hitPart == nil then return end;

    local projectilePart = projectile.Part;

    if RunService:IsServer() then
        if projectilePart:CanSetNetworkOwnership() then projectilePart:SetNetworkOwner(nil) end;
        
        if CollectionService:HasTag(hitPart, "Flammable") then
            local modFlammable = shared.require(game.ServerScriptService.ServerLibrary.Flammable);
            modFlammable:Ignite(hitPart);
        end
    end
end

return projectilePackage;