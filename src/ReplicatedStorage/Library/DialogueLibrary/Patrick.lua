local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local NpcDialogues = {};

NpcDialogues.Initial = {
	"Hmm?";
};

NpcDialogues.Dialogues = {
	{Tag="aggresiveInit"; Face="Angry"; 
		Reply="Halt! Turn back now!";};

	{Tag="banditOutpost";
		Dialogue="Could you take me to the Bandit Outpost?";
		Reply="Sure..";
		ReplyFunction=function(dialogPacket)
			local npcModel = dialogPacket.Prefab;
			if npcModel:FindFirstChild("banditOutpostInteractable") then
				local localPlayer = game.Players.LocalPlayer;
				local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);

				modData.InteractRequest(npcModel.banditOutpostInteractable, npcModel.PrimaryPart);
			end
		end};

	{Tag="banditmapGift"; Face="Happy";
		Dialogue="Hey, how's the wound?";
		Reply="It's getting better.. Oh and I want to give you this.."};

	{Tag="guide_factions"; Dialogue="You said something about starting our own faction?"; Face="Happy";
		Reply="Yeah! I'll help with distributing the information to keep the members up to date.. But I'll need 5000 gold before we begin.."}; --end

	{Tag="safehomeInit"; Face="Confident"; 
		Reply="Welcome back.";};

};

--[[
	A: Aggressive
	P: Passive
--]]


return NpcDialogues;