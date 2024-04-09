local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Interactable = require(game.ReplicatedStorage.Library.Interactables);

local remotes = game.ReplicatedStorage.Remotes;
local remoteOnTrigger = remotes.Interactable.OnTrigger;

local button = Interactable.Interface("TerminalWindow", "Use Terminal");
button.TriggerTag = "RatRecruit1";
button.Script = script;

button.HackInfo = {
	Name = "Terminal #02";
	AuthenticationLevel = "Level-3";
	Logon=true;
	ConnectedDevices = {
		["$nekronchamber#02"]={
			Logon=true;
			Name="Nekron Chamber #02";
			LastAccess="Eugene";
			SecProto="256-bit authentication keypass";
		};
	}
};

function button.OnTerminal(terminal)
	terminal:AddCommand{
		CmdId = "settemp";
		Desc = "Set the temperature of chamber.";
		Run=function(args)
			local temp = tonumber(args[1]);

			Debugger:Log("Set temp", args);
			
			if temp == nil then
				terminal.Println("Missing value for <b>settemp value</b>");
				return;
			end

			if temp < 40 or temp > 80 then
				terminal.Println("Temperature out of range. [40, 80]");
				return;
			end

			terminal.Println("Chamber #02 Temperature set to: ".. temp .." celsius");

			remoteOnTrigger:InvokeServer(script.Parent, script, {Temp=temp});
		end
	};
	
end

return button;