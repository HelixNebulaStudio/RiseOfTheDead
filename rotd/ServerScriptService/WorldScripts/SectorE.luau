local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new(script);

if RunService:IsServer() then
    modNpcs = shared.modNpcs;
end
--==

function WorldCore.onRequire()
    if RunService:IsServer() then
        shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
            local profile: ProfileRotd = shared.modProfile:WaitForProfile(player) :: ProfileRotd;
            if profile == nil then return end;

        end, 999);

        modNpcs.spawn2{
            Name = "Eugene";
            CFrame = CFrame.new(141.050186, -8.21727085, -80.1585464, 0.224951029, 0, -0.974370062, 0, 1, 0, 0.974, 0, 0.225);
        };

        modNpcs.spawn2{
            Name = "Stan";
            CFrame = CFrame.new(144.298691, -4.9482584, -86.1587524, 0, 0, 1.00000298, 0, 1, 0, -1.00000298, 0, 0);
            BindSetup = function(npcClass: NpcClass)
                npcClass.RootPart.Anchored = true;
                npcClass:GetComponent("AvatarFace"):Set("Unconscious");
            end;
        };

        local RatGoons = {
            Name1={
                SpawnCFrame=CFrame.new(28.3652916, -11.299139, -19.6912498, -0.190809801, 0, 0.98163116, 0, 1, 0, -0.98163116, 0, -0.190809801)
            };
            Name2={
                SpawnCFrame=CFrame.new(59.0210228, -11.2829905, -9.4149456, 0.309018254, 0, 0.951060355, 0, 1, 0, -0.951060355, 0, 0.309018254)
            };
            Name3={
                SpawnCFrame=CFrame.new(73.10495, -11.2829914, -82.716629, -0.29237166, 0, 0.956304789, 0, 1, 0, -0.956304789, 0, -0.292371631)
            };
            Name4={
                SpawnCFrame=CFrame.new(39.6942177, -11.2829905, -83.8387909, -0.707106769, 0, -0.707106709, 0, 1, 0, 0.707106829, 0, -0.707106769)
            };
        };

        WorldCore.RatGoons = RatGoons;
        for name, ratGoonData in pairs(RatGoons) do
            modNpcs.spawn2{
                Name = "Rat";
                CFrame = ratGoonData.SpawnCFrame;
                BindSetup = function(npcClass: NpcClass)
                    ratGoonData.NpcClass = npcClass;
                    
                    npcClass.Properties.CutsceneActive = true;
                    npcClass.Move:SetMoveSpeed("set", "default", 8);

                    task.delay(1, function()
                        npcClass.PlayAnimation("foldbackhands");
                    end)
                end;
            };
        end
    end
end


return WorldCore;