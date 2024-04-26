return function(core)
	local localPlayer = game.Players.LocalPlayer;

	core.Func[script.Name] = function()
		local shakerModule;
		while game.Players:IsAncestorOf(localPlayer) do
			shakerModule = localPlayer:FindFirstChild("ShakerModule");
			if shakerModule == nil then
				task.wait(0.1);
			end
		end
		if shakerModule == nil then return end;

	end;
end;