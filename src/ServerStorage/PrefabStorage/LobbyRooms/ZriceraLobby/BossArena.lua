local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local TweenService = game:GetService("TweenService");
local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);

local BossArenaMeta = {};
BossArenaMeta.__index = BossArenaMeta;
BossArenaMeta.Enemies = {};
local BossArena = setmetatable({}, BossArenaMeta);

--== Variables;
local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In);

--== Script;
function BossArena:SetRoom(room)
	BossArenaMeta.Room = room;
end

function BossArena:Start()
	local leftGate = script.Parent.Scene:WaitForChild("LeftGate");
	local rightGate = script.Parent.Scene:WaitForChild("RightGate");
	
	local leftCFramePoint = leftGate:GetPrimaryPartCFrame().p;
	local rightCFramePoint = rightGate:GetPrimaryPartCFrame().p;
	
	BossArena.gateRotationTag = Instance.new("NumberValue");
	BossArena.gateRotationTag.Value = 90;
	BossArena.gateRotationTag.Parent = script.Parent;
	
	BossArena.gateRotationTag:GetPropertyChangedSignal("Value"):Connect(function()
		leftGate:SetPrimaryPartCFrame(CFrame.new(leftCFramePoint) * CFrame.Angles(0, math.rad(BossArena.gateRotationTag.Value), 0));
		rightGate:SetPrimaryPartCFrame(CFrame.new(rightCFramePoint) * CFrame.Angles(0, math.rad(-BossArena.gateRotationTag.Value), 0));
	end)
	
	TweenService:Create(BossArena.gateRotationTag, tweenInfo, {Value=0}):Play();
end

function BossArena:End()
	TweenService:Create(BossArena.gateRotationTag, tweenInfo, {Value=90}):Play();
end

function Initialize()
	
end

Initialize();
return BossArena;
