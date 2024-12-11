local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local MasterMind = {};
MasterMind.__index = MasterMind;

MasterMind.RulesStr = [[
Game Rules

Objective
A secret combination of 4 colors is selected and you have to guess that combination in 8 or fewer tries to win.

How to play
From top to bottom, at each row, click on a circle and pick a color. After filling all circles in a row, you can check your guess.

- A green circle means the color and the position is correct.
- An orange circle means that the color exists in the combination but the position is not correct.
- An empty circle means that color is not in the combination at all.
]]

MasterMind.States = {
    Idle=0;
    Active=1;
    Completed=2;
    Failed=3;
};

MasterMind.Choices = {
    "Red";
    "Blue";
    "Yellow";
    "Green";
    "Pink";
    "Orange";
};

function MasterMind.new()
    local self = {
        Slots=4;
        ChoicesCount=4;
        MaxRepeatCount=2;

        SessionState = MasterMind.States.Idle;
        SessionLives = 8;
        SessionAnswer = {};
    };

    setmetatable(self, MasterMind);
    return self;
end

function MasterMind:Start(seed)
    local random = Random.new(seed);

    table.clear(self.SessionAnswer);
    self.SessionState = MasterMind.States.Active;

    for a=1, self.Slots do
        local pickedChoice = nil;

        local validPick = false;
        local breakCount = 0;
        repeat
            pickedChoice = self.Choices[random:NextInteger(1, self.ChoicesCount)];
            
            local repeatCount = 0;
            for b=1, #self.SessionAnswer do
                if self.SessionAnswer[b] == pickedChoice then
                    repeatCount = repeatCount +1;
                end
            end
            
            if repeatCount < self.MaxRepeatCount then
                validPick = true;
            elseif breakCount > self.ChoicesCount then
                validPick = true;
            end
            breakCount = breakCount +1;
        until validPick;

        table.insert(self.SessionAnswer, pickedChoice);
    end

    Debugger:StudioLog("MasterMind Start:", self, self:StringifyAnswer());

end

function MasterMind:StringifyAnswer()
    return #self.SessionAnswer > 0 and `\{{table.concat(self.SessionAnswer, ", ")}\}` or "{}";
end

function MasterMind:Submit(submitChoices)
    local sessionAns = self.SessionAnswer;

    local hintPacket = {};

    for a=1, #submitChoices do
        local subA = submitChoices[a];

        if subA == sessionAns[a] then
            -- matches
            hintPacket[a] = 1;

        else
            local exist = false;
            if table.find(sessionAns, subA) then
                exist = true;
            end

            -- exist
            if exist then
                hintPacket[a] = 2;
            else
                hintPacket[a] = 0;
            end
        end
    end
    
    -- process
    local allCorrect = true;
    for a=1, #hintPacket do
        if hintPacket[a] ~= 1 then
            allCorrect = false;
            break;
        end
    end

    if allCorrect then
        self.SessionState = MasterMind.States.Completed;
    else
        self.SessionLives = self.SessionLives -1;

        if self.SessionLives <= 0 then
            self.SessionState = MasterMind.States.Failed;

            self.Answer = self.SessionAnswer;
        end
    end

    return hintPacket, allCorrect;
end

function MasterMind:Sync()
    return {
        State = self.SessionState;
        Lives = self.SessionLives;
        Answer = self.Answer;
    };
end

task.spawn(function()
    Debugger.AwaitShared("modCommandsLibrary");

    shared.modCommandsLibrary:HookChatCommand("mastermind", {
        Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;
        Description = [[MasterMind Cmds:
        /mastermind start [slots] [choices] [seed]
            Starts a new game.
        /mastermind submit [...]
        /mastermind reveal
            Reveals the answer.
        /mastermind rules

        Examples:
            /mastermind submit Blue Green
            /mastermind submit blue green
            /mastermind submit 2 3
        ]];

        RequiredArgs = 0;
        Function = function(speaker, args)
            local profile = shared.modProfile:Get(speaker);
            local playerCache = profile.Cache;

            local action = args[1];
            
            if action == "start" then
                local slots = args[2];
                local choices = args[3];
                local seed = args[4];

                local masterMind = MasterMind.new();
                if slots then
                    masterMind.Slots = slots;
                end
                if choices then
                    masterMind.ChoicesCount = math.clamp(choices, 1, #MasterMind.Choices);
                end

                playerCache.MasterMindGame = masterMind;

                masterMind:Start(seed);

                shared.Notify(speaker, `MasterMind started!\n\tLives: {masterMind.SessionLives}\n\tSlots: {masterMind.Slots}\n\tChoices: \{{table.concat(masterMind.Choices, ", ", 1, masterMind.ChoicesCount)}\}`, "Inform");

            elseif action == "submit" then

                if playerCache.MasterMindGame == nil then
                    shared.Notify(speaker, `No mastermind games running..`, "Negative");
                    return;
                end

                local masterMind = playerCache.MasterMindGame;

                local submitChoice = {};
                for a=2, #args do
                    local argVal = tostring(args[a]);
                    local submitVal = nil;

                    for b=1, #masterMind.Choices do
                        local optStr = masterMind.Choices[b];

                        if tostring(b) == argVal then
                            submitVal = optStr;
                            break;

                        elseif optStr == argVal or optStr:lower() == argVal:lower() then
                            submitVal = optStr;
                            break;

                        elseif optStr:match(argVal) then
                            submitVal = optStr;
                            break;

                        end
                    end

                    if submitVal then
                        table.insert(submitChoice, submitVal);
                    end
                end

                if #submitChoice < masterMind.Slots then
                    shared.Notify(speaker, `Submit did not contain enough choices. Submitted: {#submitChoice}  Required: {masterMind.Slots}`, "Negative");
                    return;
                end

                shared.Notify(speaker, `Submitted: {table.concat(submitChoice, ", ")}`, "Inform");

                local hintPacket = masterMind:Submit(submitChoice);
                if masterMind.SessionState == MasterMind.States.Completed then
                    shared.Notify(speaker, `MasterMind Victory!\nAnswer: {table.concat(masterMind.SessionAnswer, ", ")}`, "Positive");

                elseif masterMind.SessionState == MasterMind.States.Failed then
                    shared.Notify(speaker, `MasterMind Defeat!\nAnswer: {table.concat(masterMind.SessionAnswer, ", ")}`, "Negative");

                else
                    local strHint = {};

                    for a=1, #hintPacket do
                        if hintPacket[a] == 1 then
                            strHint[a] = "●";
                        elseif hintPacket[a] == 2 then
                            strHint[a] = "◑";
                        else
                            strHint[a] = "○";
                        end
                    end

                    local correctCount = 0; for a=1, #hintPacket do if hintPacket[a] == 1 then correctCount = correctCount +1; end; end;
                    local wrongPosCount = 0; for a=1, #hintPacket do if hintPacket[a] == 2 then wrongPosCount = wrongPosCount +1; end; end;
                    shared.Notify(speaker, `MasterMind Correct: {correctCount}  Wrong Position: {wrongPosCount}\n\tHint: \{{table.concat(strHint, " ")}\}\n\tLives Left: {masterMind.SessionLives}`, "Inform");
                end

            elseif action == "reveal" then
                
                if playerCache.MasterMindGame == nil then
                    shared.Notify(speaker, `No mastermind games running..`, "Negative");
                    return;
                end

                local masterMind = playerCache.MasterMindGame;
                shared.Notify(speaker, `MasterMind Reveal \nAnswer: {table.concat(masterMind.SessionAnswer, ", ")}`, "Inform");

            elseif action == "rules" then
                local choicesStr = {};
                for a=1, #MasterMind.Choices do
                    table.insert(choicesStr, `[{a}] = {MasterMind.Choices[a]}`);
                end
                shared.Notify(speaker, `MasterMind {MasterMind.RulesStr}\nOptions:\n\t{table.concat(choicesStr, "\n\t")}`, "Inform");
            end

            ---shared.Notify(speaker, "Unknown action for /weather", "Negative");

            return;
        end;
    });

end)

return MasterMind;