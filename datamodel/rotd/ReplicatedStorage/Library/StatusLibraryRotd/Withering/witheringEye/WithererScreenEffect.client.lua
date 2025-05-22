local RunService = game:GetService("RunService");
--
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modMath = shared.require(game.ReplicatedStorage.Library.Util.Math);

--
local rootLayer: ImageLabel = script.Parent;
local layer2 = rootLayer:WaitForChild("layer2") :: ImageLabel;

local rate = 32;

local sound;
if sound then
	modAudio.Preload("WitherIdle", 5)
	sound = modAudio.Play("WithererIdle", script.Parent);
	sound.Volume = 0;

	local reverb = Instance.new("ReverbSoundEffect");
	reverb.Parent = sound;
end

RunService.RenderStepped:Connect(function(delta)
	local alpha = rootLayer:GetAttribute("Alpha") or 0.5;
	alpha = math.clamp(alpha, 0, 1);
	
	rootLayer.Rotation = rootLayer.Rotation + (rate*delta*alpha);
	layer2.Rotation = layer2.Rotation + (-rate/2 *delta*alpha);
	
	rootLayer.ImageTransparency = modMath.MapNum(alpha, 0, 1, 1, 0.3);
	layer2.ImageTransparency = modMath.MapNum(alpha, 0, 1, 1, 0.5);
	
	if sound then
		sound.Volume = alpha;
	end
	
	if alpha >= 1 then
		rootLayer.ImageColor3 = Color3.fromRGB(255,255,255);
		layer2.ImageColor3 = Color3.fromRGB(255,255,255);
	end
end)