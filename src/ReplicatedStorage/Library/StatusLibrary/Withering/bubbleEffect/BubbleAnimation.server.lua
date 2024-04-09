local TweenService = game:GetService("TweenService");

local localPlayer = game.Players.LocalPlayer;
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modAudio = require(game.ReplicatedStorage.Library.Audio);

--==
local model = script.Parent;
local base = model:WaitForChild("base");
local top = model:WaitForChild("top");
local particleEmitter = base:WaitForChild("ParticleEmitter");

local function fire()
	local tweenDuring = math.random(20, 30)/100;
	local tweenInfo = TweenInfo.new(tweenDuring+0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out);

	local sizeRatio = math.random(10, 60)/100;

	base.Transparency = 0;
	top.Transparency = 0;
	base.Size = Vector3.new(0.1, 0.1, 0.1);
	top.Size = Vector3.new(0.11, 0.11, 0.11);
	
	TweenService:Create(top, tweenInfo, {
		Size=(Vector3.new(1.979, 2.145, 2.145)*sizeRatio);
	}):Play();
	TweenService:Create(base, tweenInfo, {
		Size=(Vector3.new(1.94, 2.103, 2.103)*sizeRatio);
	}):Play();
	
	task.wait(tweenDuring);
	base.Transparency = 1;
	top.Transparency = 1;
	
	particleEmitter:Emit(4);

	task.wait(math.random(10, 20)/100);
end


modAudio.Play("LavaBubbling", base);

local classPlayer = shared.modPlayers.Get(localPlayer);

local modData = require(game.Players.LocalPlayer:WaitForChild("DataModule"));
local modCharacter = modData:GetModCharacter();

local rayParam = RaycastParams.new();
rayParam.FilterType = Enum.RaycastFilterType.Include;
rayParam.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain};
rayParam.IgnoreWater = true;

task.spawn(function()
	while classPlayer.Properties.Withering do
		if not workspace.Debris:IsAncestorOf(model) then
			break;
		end

		local rootPart = classPlayer.RootPart;
		local originPos = (modCharacter.CharacterProperties.GroundPoint or rootPart.Position - Vector3.new(0, 2.5, 0)) + Vector3.new(0, 4, 0);

		local dirCf = CFrame.lookAt(Vector3.zero, -Vector3.yAxis, Vector3.yAxis);
		dirCf = dirCf*CFrame.Angles(0, 0, math.rad(math.random(0, 360))); -- roll cframe
		
		local gr = modGlobalVars.GaussianRandom()/2.5;
		
		dirCf = dirCf*CFrame.Angles(math.rad(40*gr), 0, 0); --pitch cframe;
		local dir = dirCf.LookVector;

		local rayResult = workspace:Raycast(originPos, dir*8, rayParam);

		if rayResult then
			local rayPoint = rayResult.Position;
			local origin = CFrame.new(rayPoint) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);

			model:PivotTo(origin);
			fire();

		else
			game.Debris:AddItem(model, 1);
			
		end

		task.wait(math.random(20, 40)/100);
	end
end)