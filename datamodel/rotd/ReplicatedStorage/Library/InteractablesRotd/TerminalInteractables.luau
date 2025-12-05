local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local localPlayer = game.Players.LocalPlayer;

local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local Terminal = super.newPackage{
		Name = "Terminal";
        Type = "Terminal";
    };

    function Terminal.new(interactable: InteractableInstance)
        interactable.CanInteract = true;
        interactable.Label = `Use Terminal`;
    end

    function Terminal.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        if info.Action ~= info.ActionSource.Client then return end;

        local terminalWindow: InterfaceWindow = modClientGuis.getWindow("TerminalWindow");
        if terminalWindow.Visible then return end;

        terminalWindow:Open({
            Interactable = interactable;
            InteractInfo = info;
        });
    end
    
    super.registerPackage(Terminal);



    --For mission 62
    local NekronChamberTerminal01 = super.newPackage{
		Name = "NekronChamberTerminal01";
        Type = "Terminal";
    };

    function NekronChamberTerminal01.new(interactable: InteractableInstance)
        Terminal.TypePackage.new(interactable);

        local values = interactable.Values;

        values.HackInfo = {
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
        
        local function bindTerminalHook(terminalBinds)
        	terminalBinds:AddCommand{
                CmdId = "settemp";
                Desc = "Set the temperature of chamber.";
                Run=function(args)
                    local temp = tonumber(args[1]);

                    Debugger:Log("Set temp", args);
                    
                    if temp == nil then
                        terminalBinds.Println("Missing value for <b>settemp value</b>");
                        return;
                    end

                    if temp < 40 or temp > 80 then
                        terminalBinds.Println("Temperature out of range. [40, 80]");
                        return;
                    end

                    terminalBinds.Println(`Chamber #02 Temperature set to: {temp} celsius`);

                    shared.modEventService:ClientInvoke(
                        "Generic_BindClientTrigger", 
                        {SendBy = localPlayer;},
                        "shutDownHeating",
                        {Temp=temp}
                    );
                end
            };
        end
        values.BindTerminalHook = bindTerminalHook;

        values.OnChanged:Connect(function(k, v, ov)
            if k ~= "BindTerminalHook" then return end;
            Debugger:Warn(`BindTerminalHook changed`, v, ov);
        end)
    end

    super.registerPackage(NekronChamberTerminal01);

end

return interactablePackage;

