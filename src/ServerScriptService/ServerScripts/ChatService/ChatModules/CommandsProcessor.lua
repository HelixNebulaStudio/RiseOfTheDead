local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local CommandsLibrary = require(game.ReplicatedStorage.Library.CommandsLibrary);
local modCommandHandler = require(game.ReplicatedStorage.Library.CommandHandler);

local Commands = CommandsLibrary.Library;
local rbxCmds = {c=true; whisper=true; w=true; f=true; mute=true; unmute=true; e=true; emote=true; join=true; j=true; update=true;};

local function Run(ChatService)
	ChatService:RegisterProcessCommandsFunction("command", function (speakerName, message, channelId)
		if message:sub(1,1) ~= "/" then return false end;
		local speaker = game.Players:FindFirstChild(speakerName);
		
		if speaker then
			local cmd, args = modCommandHandler.ProcessMessage(message);
			if cmd == nil then return true end;
			
			local cmdKey = (cmd:sub(2, #cmd):lower());
			local cmdLib = Commands[cmdKey];
			
			if cmdLib then
				cmdLib.CmdKey = cmdKey;
				if not CommandsLibrary.HasPermissions(speaker, cmdLib) then 
					ChatService:SendMessage(speaker, channelId, 
						"Insufficient permissions.", 
						{Presist=false; MessageColor=Color3.fromRGB(255, 69, 69);}
					);
					return true
				end;
				
				if cmdLib.RequiredArgs and #args < cmdLib.RequiredArgs then
					ChatService:SendMessage(speaker, channelId, 
						"Missing arguements..\n"..(cmdLib.UsageInfo or ""), 
						{Presist=false; MessageColor=Color3.fromRGB(255, 69, 69);}
					);
					return true;
				end;
				
				if cmdLib.Cooldown and cmdLib.Debounce == nil then cmdLib.Debounce = {}; end
				if cmdLib.Debounce == nil or cmdLib.Debounce[speaker.Name] == nil or tick()-cmdLib.Debounce[speaker.Name] >= cmdLib.Cooldown then
					if cmdLib.Debounce then cmdLib.Debounce[speaker.Name] = tick(); end;
					cmdLib.Function(speaker, args);
				else
					ChatService:SendMessage(speaker, channelId, 
						"Command is on a cooldown..", 
						{Presist=false; MessageColor=Color3.fromRGB(255, 69, 69);}
					);
					return true;
				end
				
			elseif rbxCmds[cmd:sub(2, #cmd):lower()] then
			else
				ChatService:SendMessage(speaker, channelId, 
					"Unknown Command: "..cmd, 
					{Presist=false; MessageColor=Color3.fromRGB(255, 69, 69);}
				);
			end
		end
		return true;
	end);
	
	game.Players.PlayerRemoving:Connect(function(player) 
		for name, _ in pairs(Commands) do
			local lib = Commands[name];
			if lib.Debounce and lib.Debounce[player.Name] then
				lib.Debounce[player.Name] = nil;
			end
		end
	end)
end
 
return Run;