local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);

local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In);
--==
local function tweenModel(model, CF, info)
	local CFrameValue = Instance.new("CFrameValue")
	CFrameValue.Value = model:GetPrimaryPartCFrame()

	CFrameValue:GetPropertyChangedSignal("Value"):connect(function()
		model:SetPrimaryPartCFrame(CFrameValue.Value)
	end)
	
	local tween = TweenService:Create(CFrameValue, info, {Value = CF})
	tween:Play()
	
	tween.Completed:connect(function()
		CFrameValue:Destroy()
	end)
end

local BossArena = {};

function BossArena.BindLoad(room)
end

function BossArena.BindBegin(room)
	if shared.WorldName ~= "TheUnderground" and shared.WorldName ~= "BioXResearch" then return end;

	local arenaModel = room.LobbyPrefab;
	for _, obj in pairs(arenaModel.Physics:GetChildren()) do
		if not obj:IsA("Model") then continue end;

		local destructibleConfig = modDestructibles.createDestructible("Generic");
		destructibleConfig.Parent = obj;
	end

	local worldPlatforms = workspace.Environment.VexeronArena:FindFirstChild("Platforms");

	local bossNpcClass: NpcClass = room.BossNpcClasses[1];
	if bossNpcClass == nil then return end;

	bossNpcClass.HealthComp.OnHealthChanged:Connect(function(curHealth, oldHealth, damageData)
		if curHealth > bossNpcClass.HealthComp.MaxHealth/2 then return end;
		if room.DropPlatforms then return end;
		room.DropPlatforms = true;

		if worldPlatforms then
			tweenModel(worldPlatforms, 
				CFrame.new(-133.199982, -18.7500172, 438.799988, 1, 0, 0, 0, 1, 0, 0, 0, 1), 
				TweenInfo.new(4)
			);
		end
	end)
end

function BossArena.BindEnded(room)
	if shared.WorldName ~= "TheUnderground" and shared.WorldName ~= "BioXResearch" then return end;

	local worldPlatforms = workspace.Environment.VexeronArena:FindFirstChild("Platforms");
	if worldPlatforms then
		tweenModel(worldPlatforms, 
			CFrame.new(-133.199982, -3.85000014, 438.799988, 1, 0, 0, 0, 1, 0, 0, 0, 1), 
			TweenInfo.new(1)
		);
	end
end

return BossArena;