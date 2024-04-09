local OptionDialogUI = {};

local OptionBox = script.Parent.Parent.MainInterface.OptionPopup;
local closeButton = OptionBox.CloseButton;
local yesButton = OptionBox.YesButton;
local itemIcon = OptionBox.ItemImage;
local titleLabel = OptionBox.Title;
local descLabel = OptionBox.Decs;
local costLabel = OptionBox.Cost;

local onCloseFunc, onYesFunc;
local debounce = false;

closeButton.MouseButton1Click:Connect(function()
	if debounce then return end; debounce = true;
	if type(onCloseFunc) == "function" then
		onCloseFunc(closeButton);
	end
	OptionDialogUI.HideOptionBox();
end)

yesButton.MouseButton1Click:Connect(function()
	if debounce then return end; debounce = true;
	if type(onYesFunc) == "function" then
		onYesFunc(yesButton);
	end
	OptionBox.Visible = false;
end)

function OptionDialogUI.SetOptionBox(title, decs, cost, image, yesButtonText, closeButtonText, closeFunction, yesFunction)
	titleLabel.Text = title or "Option Dialog";
	descLabel.Text = decs or "Are you sure?";
	costLabel.Text = cost or "";
	itemIcon.Image = image or "";
	yesButton.Text = yesButtonText or "Yes";
	closeButton.Text = closeButtonText or "No";
	onCloseFunc = closeFunction;
	onYesFunc = yesFunction;
end

function OptionDialogUI.ShowOptionBox()
	OptionBox.Visible = true;
	debounce = false;
end

function OptionDialogUI.HideOptionBox()
	OptionBox.Visible = false;
end

return OptionDialogUI;