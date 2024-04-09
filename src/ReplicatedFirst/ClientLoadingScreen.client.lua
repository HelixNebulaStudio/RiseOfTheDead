local TeleportService = game:GetService("TeleportService");
local Players = game:GetService("Players");
local ReplicatedFirst = game:GetService("ReplicatedFirst");
 
local function enableBubbleChat()
    return {BubbleChatEnabled = true}
end
game:GetService("Chat"):RegisterChatCallback(Enum.ChatCallbackType.OnCreatingChatWindow, enableBubbleChat)

game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false);
TeleportService.LocalPlayerArrivedFromTeleport:Connect(function(customLoadingScreen, teleportData)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui");
--	ReplicatedFirst:RemoveDefaultLoadingScreen();
--	if customLoadingScreen then
--		customLoadingScreen.Parent = playerGui
--		game.Debris:AddItem(customLoadingScreen, 5);
--	end
end)