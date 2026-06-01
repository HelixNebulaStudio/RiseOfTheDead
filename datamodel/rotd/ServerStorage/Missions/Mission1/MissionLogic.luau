local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
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

		highlight.ContainerTextInfo = {
			["1"] = {
				Text = `Press [1] / <font family="rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json">Left Bumper</font> to equip pistol`;
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