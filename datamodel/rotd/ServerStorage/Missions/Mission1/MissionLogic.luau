local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");

local MissionLogic = {};

local modGuiHighlight = shared.require(game.ReplicatedStorage.Library.UI.GuiHighlight);

if RunService:IsClient() then
	local localPlayer = game.Players.LocalPlayer;
	local playerGui = localPlayer.PlayerGui;
	modGuiHighlight.HideBackground = true;

	function MissionLogic.Checkpoint2()
		local highlight = modGuiHighlight.Set("MainInterface", "MissionPinHud");
	end

	function MissionLogic.Checkpoint3()
		modGuiHighlight.FrameWorldObject(workspace.Interactables:WaitForChild("Mission1Pickup"));
		local highlight = modGuiHighlight.Set("MainInterface", "Mission1Pickup");
	end

	function MissionLogic.Checkpoint4()
		RunService.Heartbeat:Wait();

		local highlight = modGuiHighlight.Set("MainInterface", "Hotbar", "1");

		local hintText = "Press 1 to equip pistol";
		if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
			hintText = `Press <font family="rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json">Left Bumper</font> to equip pistol`;
		elseif UserInputService.PreferredInput == Enum.PreferredInput.Touch then
			hintText = `Tap here to equip pistol`;
		end

		highlight.ContainerTextInfo = {
			["1"] = {
				Text = hintText;
				TextLayout = "TCO";
			};
		}
	end

	function MissionLogic.Checkpoint5()
		local highlight = modGuiHighlight.Set("MainInterface", "MissionPinHud");
	end

	function MissionLogic.Cancel()
		modGuiHighlight.Set();
	end
end

return MissionLogic;