local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local RunService = game:GetService("RunService");

local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local localPlayer = game.Players.LocalPlayer;
--==
local statusPackage = {
    Id="Chained";
    Icon="rbxassetid://16716699240";
    Name="Chained";
    Description="You are chained to something. Maybe destroy it to break free?";
    Buff=false;
};

function statusPackage:OnTick(tickPack)
    if not RunService:IsServer() then return end;
    if tickPack.ms100 ~= true then return end;

    local playerClass = self.PlayerClass;
    if playerClass == nil then return end;

    if self.ExpireIfNoGarbage ~= true then return end;

    if #self.Garbage.Trash <= 0 then
        self.Expires = modSyncTime.GetTime();
        playerClass:SyncProperty("Chained");
        Debugger:Warn("Expire Chained");
    end
end

-- Custom Methods
function statusPackage:OnTeleport()
    if not RunService:IsServer() then return end;

    for _, obj in pairs(self.Garbage) do
        obj:Destroy();
    end
end

function statusPackage:Chain(duration: number, position: Vector3, anchorHealth: number, isHardMode: boolean)
    if not RunService:IsServer() then return end;
    local playerClass: PlayerClass = self.PlayerClass;
    if playerClass == nil then return end;

    local player: Player = playerClass:GetInstance();
    local rootPart = playerClass.RootPart;
	local rootAtt = rootPart.RootRigAttachment;
	
	position = position or rootPart.Position;
	
	local newAnchor = script.ChainAnchors:Clone();
	local anchorAtt = newAnchor:WaitForChild("Base"):WaitForChild("AnchorAtt");
	local tarRpValue: ObjectValue = newAnchor:WaitForChild("Base"):WaitForChild("TargetRootPart");
	
	local newRope = Instance.new("RopeConstraint");
	newRope.Attachment0 = anchorAtt;
	newRope.Attachment1 = rootAtt;
	newRope.Length = isHardMode and 20 or 32;
	newRope.Visible = false;
	newRope:SetAttribute("FPIgnore", true);
	newRope.Parent = rootPart;
	Debugger.Expire(newRope, duration);

	local newChains = script.Chains:Clone();
	newChains.Attachment0 = anchorAtt;
	newChains.Attachment1 = rootAtt;
	if isHardMode then
		newChains.Color = ColorSequence.new(Color3.new(0.243137, 0.196078, 0.196078), Color3.new(0.243137, 0.168627, 0.168627));
	end
	newChains.Parent = rootPart;
	Debugger.Expire(newChains, duration);

    Debugger.Expire(newAnchor, duration);
	newAnchor:PivotTo(CFrame.new(position));
	
	tarRpValue.Value = rootPart;
	
	local destructibleObj = require(newAnchor:WaitForChild("Destructible"));
	
	destructibleObj:SetHealth(anchorHealth, anchorHealth);
	function destructibleObj:OnDestroy()
		game.Debris:AddItem(newAnchor, 0);
		game.Debris:AddItem(anchorAtt, 0);
		game.Debris:AddItem(newRope, 0);
		game.Debris:AddItem(newChains, 0);
	end
	destructibleObj.Enabled = true;
	
	newAnchor.Parent = workspace.Environment;
	
	pcall(function()
		newAnchor.Base:SetNetworkOwner(player);
	end)
	
    self.Garbage:Tag(newAnchor);
	
	newAnchor.Destroying:Connect(function()
		destructibleObj:OnDestroy();
        self.Garbage:Untag(newAnchor);
	end)

    self.ExpireIfNoGarbage = true;

    
    self.Expires=modSyncTime.GetTime()+duration;
    self.Duration=duration;

    playerClass:SyncStatus(statusPackage.Id);

    return newAnchor;
end


return modStatusClass.new(statusPackage);