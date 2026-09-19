local animator: Animator = script.Parent:WaitForChild("AnimationController"):WaitForChild("Animator");

local TweenService = game:GetService("TweenService");
local localPlayer = game.Players.LocalPlayer;

local clawAnim = animator:LoadAnimation(script:WaitForChild("Claws"));
local baseAnim = animator:LoadAnimation(script:WaitForChild("Base"));

clawAnim:Play();
baseAnim:Play();
baseAnim:AdjustSpeed(0.01);

local base = script.Parent:WaitForChild("base");
local eyeAttachment = base:WaitForChild("eyeAttachment");
local eyeball = script.Parent:WaitForChild("eyeball");

task.spawn(function()
	while true do
		local rpCf = localPlayer.Character and localPlayer.Character:GetPivot() or CFrame.new();
		
		local dist = (eyeAttachment.WorldPosition-rpCf.Position).Magnitude;
		local eyePos = eyeAttachment.WorldPosition;
		
		if dist >= 64 then
			eyePos = base.Position;
		end
		
		local lookAtCf = CFrame.lookAt(eyePos, rpCf.Position);
		local tween = TweenService:Create(eyeball,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
			{
				CFrame = lookAtCf;
			}
		)
		tween:Play();
		task.wait(0.3);
	end
end)