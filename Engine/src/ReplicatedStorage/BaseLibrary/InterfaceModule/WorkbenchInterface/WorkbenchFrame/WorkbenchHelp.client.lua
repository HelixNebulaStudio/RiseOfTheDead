local modGuiObjectTween = require(script.Parent.Parent.Parent:WaitForChild("GuiObjectTween"));

local helpButton = script.Parent.wbHelp;
local helpFrame = script.Parent.Help;
local hintLabel = helpFrame.Hint;
local changeHintRemote = script.ChangeHint;

local duration = 0.25;
-- Script;
local hints = {
	[[
	Workbench Helper:
	
	To start customizing an item,
			Select an item from inventory to start working on it.
		
	Build Menu:
			Build items that you have learnt, a blueprint will be permanently unlocked after building them.
	]];
}

local function UpdateHint(a)
	hintLabel.Text = hints[a];
end

changeHintRemote.Event:Connect(UpdateHint) --cleared max depth check

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

UpdateHint(1);