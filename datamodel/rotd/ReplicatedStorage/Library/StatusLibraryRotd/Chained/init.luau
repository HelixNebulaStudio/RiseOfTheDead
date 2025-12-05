local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local RunService = game:GetService("RunService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
--==
local statusPackage = {
    Id="Chained";
    Icon="rbxassetid://16716699240";
    Name="Chained";
    Description="You are chained to something. Maybe destroy it to break free?";
    Buff=false;
	ExpiresOnDeath=true;
};

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if not RunService:IsServer() then return end;
    if tickData.ms100 ~= true then return end;

    local characterClass: CharacterClass = statusClass.StatusOwner;
    if characterClass == nil then return end;

    if statusClass.Values.ExpireIfNoGarbage ~= true then return end;

    if #statusClass.Garbage.Trash <= 0 then
        statusClass.Expires = workspace:GetServerTimeNow();
		statusClass:Sync();
    end
end

function statusPackage.Chain(statusClass: StatusClassInstance, duration: number, position: Vector3, anchorHealth: number, isHardMode: boolean)
    if not RunService:IsServer() then return end;
    local characterClass: CharacterClass = statusClass.StatusOwner;
    if characterClass == nil then return end;

    local rootPart = characterClass.RootPart;
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

	local destructConfig: Configuration = modDestructibles.createDestructible();
	destructConfig.Parent = newAnchor;

	local destructible: DestructibleInstance = modDestructibles.getOrNew(destructConfig);
	destructible.Properties.DestroyModel = false;

	destructible.HealthComp:SetMaxHealth(anchorHealth);
	destructible.HealthComp:Reset();

	destructible.OnDestroy:Connect(function()
		game.Debris:AddItem(newAnchor, 0);
		game.Debris:AddItem(anchorAtt, 0);
		game.Debris:AddItem(newRope, 0);
		game.Debris:AddItem(newChains, 0);

		Debugger.Expire(destructible.Model, 5);
	end)

	newAnchor.Parent = workspace.Environment;

	pcall(function()
		if characterClass.ClassName ~= "PlayerClass" then return end;
		local player: Player = (characterClass :: PlayerClass):GetInstance();
		newAnchor.Base:SetNetworkOwner(player);
	end)

    statusClass.Garbage:Tag(newAnchor);

	newAnchor.Destroying:Connect(function()
		destructible.HealthComp:SetIsDead(true);
        statusClass.Garbage:Untag(newAnchor);
	end)

    statusClass.Values.ExpireIfNoGarbage = true;


    statusClass.Expires = workspace:GetServerTimeNow()+duration;
    statusClass.Duration = duration;

	statusClass:Sync();
	
    return newAnchor;
end


return modStatusClass.new(statusPackage);