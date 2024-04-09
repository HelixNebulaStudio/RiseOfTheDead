local TweenService = game:GetService("TweenService");

local lightPart = script.Parent:WaitForChild("alertLight3");
local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1);
---
local rotY = lightPart.Orientation.Y;
TweenService:Create(lightPart, tweenInfo, {Orientation=Vector3.new(360, rotY, 0)}):Play();