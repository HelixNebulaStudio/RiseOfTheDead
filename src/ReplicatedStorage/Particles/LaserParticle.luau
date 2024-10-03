local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local LaserParticle = {};
LaserParticle.__index = LaserParticle;

LaserParticle.ActiveBeams = {};
LaserParticle.HeartbeatConn = nil;

local terrain = workspace.Terrain;

local beamTemplate: Beam = script:WaitForChild("Laser");
local dotTemplate: ParticleEmitter = script:WaitForChild("LaserDot");
-- 

function LaserParticle.new()
    local self = {
        Beam=beamTemplate:Clone();
        OriginAttachment=Instance.new("Attachment");
        DestAttachment=Instance.new("Attachment");
        LaserDot=dotTemplate:Clone();
        Enabled=false;

        TargetPosition = Vector3.zero;
        PointAccuracy = 0;
        Seed=math.random(100, 999)/1000;

        -- var;
        Noise=0;
    };

    self.OriginAttachment.Name = "LaserOrigin";
    self.DestAttachment.Name = "LaserDest";

    self.Beam.Attachment0 = self.OriginAttachment;
    self.Beam.Attachment1 = self.DestAttachment;

    self.LaserDot.Parent = self.Beam.Attachment1;

    setmetatable(self, LaserParticle);
    return self;
end

function LaserParticle:SetActive(v)
    if self.Enabled == v then return end;

    self.Enabled = v == true;

    local existIndex = table.find(LaserParticle.ActiveBeams, self);
    if existIndex == nil then
        if self.Enabled then
            table.insert(LaserParticle.ActiveBeams, self);
        end
    else
        if self.Enabled == false then
            for a=#LaserParticle.ActiveBeams, 1, -1 do
                if LaserParticle.ActiveBeams[a] == self then
                    table.remove(LaserParticle.ActiveBeams, a);
                end
            end
        end
    end
    LaserParticle.Refresh();
end

function LaserParticle:Test(character: Model)
    self.OriginAttachment.Parent = terrain;
    self.DestAttachment.Parent = terrain;
    
    self.Beam.Parent = terrain;

    local rootPart = character.PrimaryPart :: BasePart;
    local originPos = rootPart.Position;

    for a=0, 128 do
        local semiSphereRng = CFrame.Angles(0, math.rad(math.random(1, 360)), 0) * CFrame.Angles(math.rad(math.random(20, 65)), 0, 0) * CFrame.new(0, 64, 0);
        local part = Debugger:PointPart(originPos + semiSphereRng.Position);
        part.Size = Vector3.one;
    end
    local semiSphereRng = CFrame.Angles(0, math.rad(math.random(1, 360)), 0) * CFrame.Angles(math.rad(math.random(6, 90)), 0, 0) * CFrame.new(0, 64, 0);
    
    local raycastParams = RaycastParams.new();
    raycastParams.FilterType = Enum.RaycastFilterType.Include;

    local updateSemiSphereRngTick = tick();
    task.spawn(function()
        local filterList = {workspace.Terrain; workspace.Environment; workspace.Entity;};
        for _, player in pairs(game.Players:GetPlayers()) do
            if player.Character == nil then continue end;
            table.insert(filterList, player.Character);
        end
        raycastParams.FilterDescendantsInstances = filterList;

        while true do
            task.wait();

            local laserOrigin = CFrame.new(originPos + semiSphereRng.Position);
            self.OriginAttachment.WorldCFrame = laserOrigin;
    
            if tick()-updateSemiSphereRngTick >= 10 then
                updateSemiSphereRngTick = tick();
                semiSphereRng = CFrame.Angles(0, math.rad(math.random(1, 360)), 0) * CFrame.Angles(math.rad(math.random(20, 80)), 0, 0) * CFrame.new(0, 64, 0);
            end
            
            local targetPos = rootPart.Position;

            self.TargetPosition = targetPos;
            self.PointAccuracy = 6;

            self:SetActive(true);
        end
    end)

end

function LaserParticle:Destroy()
    self.Enabled = false;
    LaserParticle.Refresh();
    
    self.Beam.Enabled = false;
    self.LaserDot.Enabled = false;
    task.wait();

    game.Debris:AddItem(self.Beam, 0);
    self.Beam = nil;
    game.Debris:AddItem(self.OriginAttachment, 0);
    self.OriginAttachment = nil;
    game.Debris:AddItem(self.DestAttachment, 0);
    self.DestAttachment = nil;

end

function LaserParticle.Refresh()
    local activeBeams = LaserParticle.ActiveBeams;

    if #activeBeams <= 0 then
        if LaserParticle.HeartbeatConn then
            LaserParticle.HeartbeatConn:Disconnect();
            LaserParticle.HeartbeatConn = nil;
        end
        return;
    end

    -- #activeBeams > 0
    if LaserParticle.HeartbeatConn == nil then
        local raycastParams = RaycastParams.new();
        raycastParams.FilterType = Enum.RaycastFilterType.Include;

        LaserParticle.HeartbeatConn = RunService.Heartbeat:Connect(function()
            local filterList = CollectionService:GetTagged("PlayerCharacters");
            table.insert(filterList, terrain);
            table.insert(filterList, workspace.Environment);
            table.insert(filterList, workspace.Entity);
            raycastParams.FilterDescendantsInstances = filterList;

            for a=1, #activeBeams do
                local laserObj = activeBeams[a];

                if laserObj.Enabled == false then
                    laserObj.Beam.Enabled = false;
                    laserObj.LaserDot.Enabled = false;

                    continue;
                end

                laserObj.Noise = laserObj.Noise + 0.01;
                local noise = laserObj.Noise;
                local rngPos = Vector3.new(
                    math.noise(laserObj.Seed, noise), 
                    math.noise(laserObj.Seed+0.2, noise), 
                    math.noise(laserObj.Seed+0.4, noise)
                ) * laserObj.PointAccuracy;
                
                
                local laserOrigin = laserObj.OriginAttachment.WorldCFrame;
                local targetPos = laserObj.TargetPosition + rngPos;
    
                local dir = (targetPos - laserOrigin.Position).Unit;

                local rayresult = workspace:Raycast(laserOrigin.Position, dir*128, raycastParams);
                if rayresult and rayresult.Instance then
                    laserObj.Beam.Enabled = true;
                    laserObj.LaserDot.Enabled = true;
                    laserObj.DestAttachment.WorldCFrame = CFrame.new(rayresult.Position);

                else
                    laserObj.Beam.Enabled = false;
                    laserObj.LaserDot.Enabled = false;

                end
            end
        end)
    end
end

return LaserParticle;