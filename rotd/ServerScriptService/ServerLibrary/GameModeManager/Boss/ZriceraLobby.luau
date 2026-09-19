local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In);
--==
local BossArena = {};

function BossArena.BindLoad(room)
end

function BossArena.BindBegin(room)
	if shared.WorldName ~= "TheWarehouse" and shared.WorldName ~= "BioXResearch" then return end;

	local arenaModel = room.LobbyPrefab;

	local leftGate = arenaModel.Scene:WaitForChild("LeftGate");
	local rightGate = arenaModel.Scene:WaitForChild("RightGate");
	
	local leftCFramePoint = leftGate:GetPrimaryPartCFrame().p;
	local rightCFramePoint = rightGate:GetPrimaryPartCFrame().p;
	
	local gateRotTag = Instance.new("NumberValue");
	gateRotTag.Value = 90;
	gateRotTag.Parent = arenaModel;
	room.GateRotTag = gateRotTag;
	
	gateRotTag:GetPropertyChangedSignal("Value"):Connect(function()
		leftGate:SetPrimaryPartCFrame(CFrame.new(leftCFramePoint) * CFrame.Angles(0, math.rad(gateRotTag.Value), 0));
		rightGate:SetPrimaryPartCFrame(CFrame.new(rightCFramePoint) * CFrame.Angles(0, math.rad(-gateRotTag.Value), 0));
	end)
	
	TweenService:Create(gateRotTag, tweenInfo, {Value=0}):Play();
end

function BossArena.BindEnded(room)
	if shared.WorldName ~= "TheWarehouse" and shared.WorldName ~= "BioXResearch" then return end;
	if room.GateRotTag == nil then return end;
	TweenService:Create(room.GateRotTag, tweenInfo, {Value=90}):Play();
end

return BossArena;