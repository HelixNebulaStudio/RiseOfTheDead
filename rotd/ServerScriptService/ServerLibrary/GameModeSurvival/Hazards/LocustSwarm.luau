local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
 
--==
local Hazard = {
	Title = "Locust Swarm";
	Description = "Locust swarming towards you!";
	Controller = nil;
};
Hazard.__index = Hazard;
--==
function Hazard.onRequire()
    locustSwarmPrefab = game.ServerStorage.Prefabs.Objects:WaitForChild("LocustSwarm");
end

function Hazard.new()
	local self = {
        Locusts = {};
        StartTick = tick();
    };
	
	setmetatable(self, Hazard);
	return self;
end

function Hazard:Load()
end

function Hazard:Begin()
	local controller = self.Controller;
    
    for _, player in ipairs(controller.Players) do
        local char = player.Character;
        if not workspace:IsAncestorOf(char) then continue end;
        local new = locustSwarmPrefab:Clone();

        local cfValue = Instance.new("CFrameValue");
        cfValue.Name = "CFrameValue";
        cfValue.Value = char:GetPivot() * CFrame.new(
            math.random(1, 2) == 1 and 4000 or -4000,
            0,
            math.random(1, 2) == 1 and 4000 or -4000
        );
        new:PivotTo(cfValue.Value);
        cfValue.Parent = new;

        cfValue:GetPropertyChangedSignal("Value"):Connect(function()
            new:PivotTo(cfValue.Value - Vector3.yAxis*3);
        end)

        local fliesSnd: Sound = modAudio.Play("Flies");
        fliesSnd.Volume = 1;
        fliesSnd.RollOffMaxDistance = 64;
        fliesSnd.RollOffMinDistance = 17;
        fliesSnd.Parent = new.PrimaryPart;

        new.Parent = workspace.Debris;

        task.spawn(function()
            while workspace:IsAncestorOf(char) do
                if not workspace:IsAncestorOf(new) then break; end;

                local charCf = char:GetPivot();

                local tl = tick() - self.StartTick;
                local fS = 0.05;
                fS += 0.3 * math.clamp((tl/150), 0.05, 1);

                local newCf = cfValue.Value:Lerp(charCf, fS);

                TweenService:Create(cfValue, TweenInfo.new(1.05, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
                    Value = newCf;
                }):Play();

                task.wait(1);

                local radius = new:GetAttribute("Radius");
                local playerDist = player:DistanceFromCharacter(newCf.Position);
                if playerDist <= radius then
                    modStatusEffects.Slowness(player, 14, 1.1);
                end
            end
        end)

        self.Locusts[player] = new;
    end

    controller.StageGarbage:Tag(function()
        for _, obj in pairs(self.Locusts) do
            Debugger.Expire(obj, 0);
        end
        table.clear(self.Locusts);
    end);
end

function Hazard:Tick()
end

function Hazard:End()
end

return Hazard;
