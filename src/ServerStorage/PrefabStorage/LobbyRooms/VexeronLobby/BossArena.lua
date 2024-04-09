local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local TweenService = game:GetService("TweenService");
local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);

local worldPlatforms = workspace.Environment.VexeronArena:FindFirstChild("Platforms");

local BossArenaMeta = {};
BossArenaMeta.__index = BossArenaMeta;
BossArenaMeta.Enemies = {};
local BossArena = setmetatable({}, BossArenaMeta);

local dropPlatforms = false;
--== Variables;
local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In);


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

--== Script;
function BossArena:SetRoom(room)
	BossArenaMeta.Room = room;
end

function BossArena:Load()
	if BossArenaMeta.physicsObjects then
		for _, obj in pairs(BossArenaMeta.physicsObjects:GetChildren()) do
			if obj:IsA("Model") then
				local destructibleModule = obj:FindFirstChild("Destructible");
				if destructibleModule then
					require(destructibleModule).Enabled = false;
				end
			end
		end
	end
end

function BossArena:Start()
	if BossArenaMeta.physicsObjects then
		for _, obj in pairs(BossArenaMeta.physicsObjects:GetChildren()) do
			if obj:IsA("Model") then
				obj.PrimaryPart.Anchored = false;
				
				local destructibleModule = obj:FindFirstChild("Destructible");
				if destructibleModule then
					require(destructibleModule).Enabled = true;
				end
			end
		end
	end
	local bossNpcModule = self.Room and self.Room.BossNpcModules and #self.Room.BossNpcModules > 0 and self.Room.BossNpcModules[1];
	if bossNpcModule and bossNpcModule.Humanoid then
		local humanoid = bossNpcModule.Humanoid;
		humanoid.HealthChanged:Connect(function()
			if not dropPlatforms and humanoid.Health <= humanoid.MaxHealth/2 then
				dropPlatforms = true;
				
				if worldPlatforms then
					tweenModel(worldPlatforms, 
						CFrame.new(-133.199982, -18.7500172, 438.799988, 1, 0, 0, 0, 1, 0, 0, 0, 1), 
						TweenInfo.new(4));
				end
			end
		end)
	end
end

function BossArena:End()
	if worldPlatforms then
		tweenModel(worldPlatforms, 
			CFrame.new(-133.199982, -3.85000014, 438.799988, 1, 0, 0, 0, 1, 0, 0, 0, 1), 
			TweenInfo.new(1));
	end
end

function Initialize()
	BossArenaMeta.physicsObjects = script.Parent:WaitForChild("Physics");
	if worldPlatforms then
		tweenModel(worldPlatforms, 
			CFrame.new(-133.199982, -3.85000014, 438.799988, 1, 0, 0, 0, 1, 0, 0, 0, 1), 
			TweenInfo.new(1));
	end
end

Initialize();
return BossArena;