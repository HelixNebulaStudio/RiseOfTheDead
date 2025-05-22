local modInterface = shared.require(script.Parent.Parent.InterfaceModule);
local modGuiObjectTween = shared.require(script.Parent.Parent.Parent.GuiObjectTween);

local helpButton = script.Parent.invHelp;
local helpFrame = script.Parent.Help;

local duration = 0.25;
-- Script;

modGuiObjectTween.FadeTween(helpFrame, modGuiObjectTween.FadeDirection.Out, TweenInfo.new(0.1));
helpButton.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseMovement then
		helpFrame.Visible = true;
		modGuiObjectTween.FadeTween(helpFrame, modGuiObjectTween.FadeDirection.In, TweenInfo.new(duration));	
    end
end)
	
helpButton.InputEnded:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseMovement then
		modGuiObjectTween.FadeTween(helpFrame, modGuiObjectTween.FadeDirection.Out, TweenInfo.new(duration));
		wait(duration);
		helpFrame.Visible = false;
    end
end)

script.Parent:GetPropertyChangedSignal("Visible"):Connect(function()
	if not script.Parent.Visible then
		modGuiObjectTween.FadeTween(helpFrame, modGuiObjectTween.FadeDirection.Out, TweenInfo.new(0.1));
	end
end)