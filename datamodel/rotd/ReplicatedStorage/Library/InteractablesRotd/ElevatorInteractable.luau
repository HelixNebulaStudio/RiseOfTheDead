local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local ElevatorList = {};
if RunService:IsServer() then
    
end

local interactablePackage = {};
--==
function InitElevator(interactable: InteractableInstance)
    local elevatorId = interactable.Values.ElevatorId;

    local elevatorModel = workspace.Environment:WaitForChild(elevatorId);
    local base = elevatorModel:WaitForChild("Base");
    local liftBase = elevatorModel:WaitForChild("LiftBase");

    local elevatorObj = ElevatorList[elevatorId];
    if elevatorObj == nil then
        elevatorObj = {
            Model = nil;
            BaseCFrame = nil;
            FloorCFrames = {};
        };
        ElevatorList[elevatorId] = elevatorObj;

        elevatorObj.Model = elevatorModel;
        elevatorObj.BaseCFrame = base.CFrame;

        elevatorModel:SetAttribute("CurrentFloor", 1);
        elevatorModel:SetAttribute("IsActive", false);

        function elevatorObj.GoToFloor(setFloor)
            local floorCf = elevatorObj.FloorCFrames[setFloor];
            if floorCf == nil then 
                Debugger:Warn(`Floor does not exist {setFloor}`);
                return;
            end;

            elevatorModel:SetAttribute("IsActive", true);

            local travelTweenInfo = TweenInfo.new(8);
            local tween: Tween = TweenService:Create(liftBase, travelTweenInfo, {
                CFrame = elevatorObj.BaseCFrame * floorCf;
            });
            tween.Completed:Once(function(status)
                if status ~= Enum.PlaybackState.Completed then return end;
                elevatorModel:SetAttribute("CurrentFloor", setFloor);
                elevatorModel:SetAttribute("IsActive", false);
            end)
            tween:Play();

        end
    end;

    local setFloor = interactable.Values.SetFloor;
    local floorCFrame = interactable.Values.FloorCFrame;
    
    if setFloor and floorCFrame then
        elevatorObj.FloorCFrames[setFloor] = floorCFrame;
    end
    Debugger:StudioLog(`InitElevator {setFloor}`, elevatorObj);
end

function interactablePackage.init(super) -- Server/Client
    local Elevator = {
		Name = "Elevator";
        Type = "Button";

        InteractDuration = 1;
    };

    function Elevator.new(interactable: InteractableInstance, player: Player)
        local config: Configuration = interactable.Config;
        local elevatorId = config:GetAttribute("ElevatorId") :: string;
        local setFloor = config:GetAttribute("SetFloor") :: number;
        local setDir = config:GetAttribute("SetDirection") :: string;
        local floorCFrame = config:GetAttribute("FloorCFrame") :: CFrame;

        interactable.CanInteract = true;
        interactable.Label = `Use Elevator`;

        interactable.Values.ElevatorId = elevatorId;
        interactable.Values.SetFloor = setFloor;
        interactable.Values.SetDir = setDir;
        interactable.Values.FloorCFrame = floorCFrame;

        if RunService:IsClient() then return end;

        task.spawn(InitElevator, interactable);
    end

    function Elevator.BindDestroy(interactable: InteractableInstance, player: Player)
        
    end

    function Elevator.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        interactable.TypePackage.BindInteract(interactable, info);
        if info.Action ~= "Server" then return end;

        local elevatorId = interactable.Values.ElevatorId;
        local setFloor = interactable.Values.SetFloor;
        local setDir = interactable.Values.SetDir;

        local elevatorObj = ElevatorList[elevatorId];
        if elevatorObj == nil then Debugger:Warn(`Elevator does not exist {elevatorId}`); return end;

        local elevatorModel = elevatorObj.Model;
        local curFloor = elevatorModel:GetAttribute("CurrentFloor", 1);
        local isActive = elevatorModel:GetAttribute("IsActive", false);

        Debugger:StudioLog(`Elevator elevatorId({elevatorId}) curFloor({curFloor}) isActive({isActive}) setFloor({setFloor}) setDir({setDir})`, elevatorObj);

        if isActive then return end;
        if curFloor == setFloor then return end;

        local newFloor = setFloor;
        if setDir then
            if setDir == "Up" then
                newFloor = curFloor + 1;
            elseif setDir == "Down" then
                newFloor = curFloor - 1;
            end
        end
        elevatorObj.GoToFloor(newFloor);

    end
    
    -- When interactable pops up on screen.
    function Elevator.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        if RunService:IsServer() then return end;
        
        local elevatorId = interactable.Values.ElevatorId;
        local elevatorModel = workspace.Environment:WaitForChild(elevatorId);

        local curFloor = elevatorModel:GetAttribute("CurrentFloor");
        local isActive = elevatorModel:GetAttribute("IsActive");

        if isActive then
			interactable.CanInteract = false;
			interactable.Label = "Lift is moving..";
			
        else
            if interactable.Values.SetFloor then
                if curFloor == interactable.Values.SetFloor then
                    interactable.CanInteract = false;
                    interactable.Label = "Lift Arrived";
                else
                    interactable.CanInteract = true;
                    interactable.Label = "Call Lift";
                end

            elseif interactable.Values.SetDir then
                interactable.CanInteract = true;
                if interactable.Values.SetDir == "Up" then
                    interactable.Label = "Go Up";
                elseif interactable.Values.SetDir == "Down" then
                    interactable.Label = "Go Down";
                end
            end
		end
    end


    super.registerPackage(Elevator);

end

return interactablePackage;

