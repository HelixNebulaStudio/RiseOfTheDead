local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local Component = {};
Component.ClassName = "NpcComponent";
Component.__index = Component;
--==

function Component.new(npcClass: NpcClass)
	local self = {
		NpcClass = npcClass;

		HookActive = false;
		TendrilRoot = nil;
	};
	
	setmetatable(self, Component);
	return self;
end

function Component:NewTendril(targetAtt: Attachment, isFake: boolean)
	local npcClass = self.NpcClass;
	if npcClass.RootPart:FindFirstChild("GrapplerHook"..targetAtt.Name) then
		return;
	end

	local newRope = Instance.new("RopeConstraint");
	newRope.Name = "GrapplerHook".. targetAtt.Name;
	newRope.Parent = npcClass.RootPart;

	newRope.Attachment0 = self.TendrilRoot;
	newRope.Attachment1 = targetAtt;

	newRope.Length = 16;

	if isFake == true then
		newRope.Restitution = 1;
		newRope.Visible = true;
		newRope.Thickness = 0.2;
		newRope.Color = BrickColor.new(Color3.fromRGB(86, 36, 36));
	end

	local pullTimer = 10;
	local level = npcClass.Properties.Level or 1;
	if level >= 10 then
		pullTimer = 8;

	elseif level >= 35 then
		pullTimer = 6;

	elseif level >= 50 then
		pullTimer = 4;

	end

	TweenService:Create(newRope, TweenInfo.new(pullTimer, Enum.EasingStyle.Linear), {
		Length = 4;
	}):Play();
end

function Component:__call(enemyCharacterClass: CharacterClass)
	local npcClass: NpcClass = self.NpcClass;
	if self.HookActive then return end;

	local targetAtt = enemyCharacterClass.RootPart:FindFirstChild("RootRigAttachment");
	if targetAtt == nil then return; end

	local isTargetHooked = enemyCharacterClass.Character:GetAttribute("GrapplerHooked");
	if isTargetHooked ~= nil then return; end;

	local targetCharacter = enemyCharacterClass.Character;
	if self.TendrilRoot == nil then
		self.TendrilRoot = Instance.new("Attachment");

		local linkPart: BasePart = Debugger:CFrameLinkPart(npcClass.Character:WaitForChild("UpperTorso"));
		linkPart.Transparency = 1;
		linkPart.Parent = npcClass.Character;

		linkPart.Destroying:Connect(function()
			if targetCharacter:GetAttribute("GrapplerHooked") == npcClass.Id then
				targetCharacter:SetAttribute("GrapplerHooked", nil);
			end
			self.HookActive = false;
			self.TendrilRoot = nil;

			npcClass.Properties.LastGrappleTick = tick();
		end)

		npcClass.Garbage:Tag(enemyCharacterClass.HealthComp.OnIsDeadChanged:Connect(function()
			if not enemyCharacterClass.HealthComp.IsDead then return end;
			game.Debris:AddItem(linkPart, 0);
		end))

		if enemyCharacterClass.ClassName == "PlayerClass" then
			local player: Player = (enemyCharacterClass :: PlayerClass):GetInstance();
			linkPart:SetNetworkOwner(player);
		end

		self.TendrilRoot.Parent = linkPart;
		self.TendrilRoot.CFrame = CFrame.new(0, 0.282, 0);
	end

	self.HookActive = true;
	targetCharacter:SetAttribute("GrapplerHooked", npcClass.Id);

	self:NewTendril(targetAtt);

	task.delay(0.1, function()
		local tarCharDesc = targetCharacter:GetDescendants();
		local tarAttsList = {};

		for a=1, #tarCharDesc do
			local charChild = tarCharDesc[a];
			local tarCharDecPar = charChild.Parent;

			if charChild:IsA("Attachment") 
				and charChild.Name ~= "UpperTorsoAttachment"
				and charChild.Name ~= "RootRigAttachment"
				and charChild.Name:find("Foot") == nil 
				and charChild.Name:find("Ankle") == nil
				and charChild.Name:find("Leg") == nil
				and tarCharDecPar
				and tarCharDecPar.Name ~= "Head" then

				table.insert(tarAttsList, charChild);
			end
		end

		if #tarAttsList <= 0 then return end;

		for a=1, math.random(4, 6) do
			local att = table.remove(tarAttsList, math.random(1, #tarAttsList));
			self:NewTendril(att, true);
		end
	end)

	modAudio.Play(math.random(1, 2) == 1 and "BulletBodyImpact" or "BulletBodyImpact2", enemyCharacterClass.RootPart);
end

return Component;