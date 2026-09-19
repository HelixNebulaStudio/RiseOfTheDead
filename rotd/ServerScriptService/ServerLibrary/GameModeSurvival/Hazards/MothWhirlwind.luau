local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local modProjectile = shared.require(game.ReplicatedStorage.Library.Projectile);

--==
local Hazard = {
	Title = "Moth Whirlwind";
	Description = "Avoid getting caught by the Whirlwind!";
	Controller = nil;
};
Hazard.__index = Hazard;
--==
function Hazard.onRequire()
    
end

function Hazard.new()
	local self = {
        StartTick = tick();
    };
	
	setmetatable(self, Hazard);
	return self;
end

function Hazard:Load()
end

function Hazard:Begin()
end

function Hazard:Tick()
    if self.LastSpawnTick and tick() < self.LastSpawnTick then return end;
    self.LastSpawnTick = tick() + math.random(5, 6);

	local controller = self.Controller;
    local player = controller.Players[math.random(1, #controller.Players)];

    local char = player.Character;
    if not workspace:IsAncestorOf(char) then return end;

    local charPos = char:GetPivot().Position;

    local originCf = CFrame.lookAlong(charPos + Vector3.yAxis*8, -Vector3.zAxis) 
    originCf = originCf * CFrame.Angles(0, math.random(0, 360), 0) * CFrame.new(originCf.LookVector * 140);
    local projectileInstance: ProjectileInstance = modProjectile.fire("mothwhirlwind", {
        OriginCFrame = originCf;
    });

    modProjectile.serverSimulate(projectileInstance, {
        Velocity = -originCf.LookVector * math.random(30, 50);
    });

end

function Hazard:End()
end

return Hazard;
