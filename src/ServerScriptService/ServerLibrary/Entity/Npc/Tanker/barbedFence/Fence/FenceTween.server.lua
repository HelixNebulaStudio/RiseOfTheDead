--!strict

local TweenService: TweenService = game:GetService("TweenService");
local part: BasePart = script.Parent;

local baseSize = Vector3.new(3.459, 12, 0.633);
local basePos = part.Position;

part.Position = basePos - Vector3.new(0, baseSize.Y/2, 0);
part.Size = baseSize * Vector3.new(1, 0, 1);
task.wait(0.1);
TweenService:Create(part, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
	Position = basePos;
	Size = baseSize;
}):Play();

