local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local Minesweeper = {};
Minesweeper.__index = Minesweeper;

Minesweeper.States = {
    Idle=0;
    Active=1;
    Completed=2;
    Failed=3;
};

function Minesweeper.new()
    local self = {
        Grid = Vector2.new(8, 8);
        MinesRatioRange = {Min=0.15; Max=0.2};

        SessionState = Minesweeper.States.Idle;
        Minefield = {};
        LastMine = nil;
        MinesFound = 0;
    };

    setmetatable(self, Minesweeper);
    return self;
end

function Minesweeper:GetMineAtPoint(x, y, new: boolean?)
    if x > self.Grid.X or y > self.Grid.Y or x <= 0 or y <= 0 then return end;

    local r;
    for a=1, #self.Minefield do
        local mineInfo = self.Minefield[a];
        if mineInfo.X == x and mineInfo.Y == y then
            r = mineInfo;
            break;
        end
    end

    if r == nil and new == true then
        local mineInfo = {
            X=x;
            Y=y;
        }
        table.insert(self.Minefield, mineInfo);
        r = mineInfo;
    end

    return r;
end

local SurroundingGrid = {
    {X=1; Y=0};
    {X=-1; Y=0};
    {X=0; Y=1};
    {X=0; Y=-1};

    {X=-1; Y=1};
    {X=1; Y=1};

    {X=-1; Y=-1};
    {X=1; Y=-1};
};

function Minesweeper:GetAroundPoint(x, y, new: boolean)
    local rList = {};

    for a=1, #SurroundingGrid do
        local surrVec = SurroundingGrid[a];

        local mineInfo = self:GetMineAtPoint(x+surrVec.X, y+surrVec.Y, new);
        if mineInfo then
            table.insert(rList, mineInfo);
        end
    end

    return rList;
end

function Minesweeper:Start(seed, param)
    local random = Random.new(seed);

    table.clear(self.Minefield);
    self.LastMine = nil;
    self.MinesFound = 0;
    self.SessionState = Minesweeper.States.Active;

    local total = self.Grid.X * self.Grid.Y;

    local minesRange = {Min=math.floor(total*self.MinesRatioRange.Min); Max=math.ceil(total*self.MinesRatioRange.Max); };
    local minesCount = random:NextInteger(minesRange.Min, minesRange.Max);

    repeat
        local x = random:NextInteger(1, self.Grid.X);
        local y = random:NextInteger(1, self.Grid.Y);

        local mineInfo = self:GetMineAtPoint(x, y, true);
        if mineInfo then
            mineInfo.Mine = 1;
        end
    until #self.Minefield >= minesCount;

    for a=1, #self.Minefield do
        local pointMineInfo = self.Minefield[a];

        local surrMineInfoList = self:GetAroundPoint(pointMineInfo.X, pointMineInfo.Y, true);
        for _, mineInfo in pairs(surrMineInfoList) do
            mineInfo.NearbyMines = (mineInfo.NearbyMines or 0) +1;
        end
    end

    param = param or {};

    if param.UncoverEmpty then
        for y=1, self.Grid.Y do
            for x=1, self.Grid.X do
                local mineInfo = self:GetMineAtPoint(x, y);
                if mineInfo == nil then
                    self:Uncover(x, y);
                end
            end
        end
    end
end

function Minesweeper:GetEmptyFields(x, y)
    local r = {};

    local mineInfo = self:GetMineAtPoint(x, y);
    if mineInfo and mineInfo.NearbyMines and mineInfo.NearbyMines > 0 then
        return r;
    end

    local scanned = {};

    local function scan(x, y)
        for a=1, 4 do
            local offset = SurroundingGrid[a];
            local vecX, vecY = x+offset.X, y+offset.Y;

            if vecX <= 0 or vecX > self.Grid.X then continue end;
            if vecY <= 0 or vecY > self.Grid.Y then continue end;

            local vecKey = `{vecX},{vecY}`;
            if scanned[vecKey] then continue end;

            local mineInfo = self:GetMineAtPoint(vecX, vecY, true);
            scanned[vecKey] = mineInfo;

            if mineInfo then
                table.insert(r, mineInfo);
            end

            if mineInfo and mineInfo.NearbyMines and mineInfo.NearbyMines > 0 then continue end; 
            scan(vecX, vecY);
        end
    end
    scan(x, y);

    return r;
end

function Minesweeper:Uncover(x, y)
    if self.SessionState == Minesweeper.States.Idle then Debugger:Warn("Minesweeper session is idle."); return end
    if self.SessionState == Minesweeper.States.Completed then Debugger:Warn("Minesweeper session is complete."); return end;
    if self.SessionState == Minesweeper.States.Failed then Debugger:Warn("Minesweeper session is failed."); return end;
    
    local uncoverMineInfo = self:GetMineAtPoint(x, y);
    
    if uncoverMineInfo == nil then
        uncoverMineInfo = self:GetMineAtPoint(x, y, true);

        local list = self:GetEmptyFields(x, y);
        for a=1, #list do
            local mineInfo = list[a];
            mineInfo.Show = true;
        end
    end

    uncoverMineInfo.Show = true;

    local uncoveredMine = (uncoverMineInfo and uncoverMineInfo.Mine and uncoverMineInfo.Mine > 0);
    if uncoveredMine then
        self.LastMine = uncoverMineInfo;
        self.MinesFound = self.MinesFound +1;
    end
    return uncoveredMine;
end

function Minesweeper:Sync()
    local field = {};

    for a=1, #self.Minefield do
        local mineInfo = self.Minefield[a];

        if mineInfo.Show == true then
            table.insert(field, {
                X=mineInfo.X;
                Y=mineInfo.Y;
                M=mineInfo.Mine;
                C=mineInfo.NearbyMines;
            });
        end
    end

    return {
        State = self.SessionState;
        Field = field;
        LastMine = self.LastMine;
        MinesFound = self.MinesFound;
    };
end

function Minesweeper:StringifyMinefield(renderType)
    local r = ``;

    for y=1, self.Grid.Y do
        for x=1, self.Grid.X do
            if x == 1 then r = r..`|`; end

            local mineInfo = self:GetMineAtPoint(x, y);

            if renderType == 1 then
                if mineInfo and mineInfo.Mine then
                    r = r..` x |`;
                else
                    local nearbyMines = mineInfo and mineInfo.NearbyMines or 0;
                    r = r..` {nearbyMines} |`;
                end

            else
                if mineInfo and mineInfo.Show then
                    if mineInfo and mineInfo.Mine then
                        r = r..` x |`;
                    else
                        local nearbyMines = mineInfo and mineInfo.NearbyMines or 0;
                        r = r..` {nearbyMines} |`;
                    end

                else
                    r = r..` ■ |`;
                end

            end

            if x == self.Grid.X and y ~= self.Grid.Y then r = r..`\n`; end;
        end
    end

    return r;
end

task.spawn(function()
	Debugger.AwaitShared("modCommandsLibrary");

	shared.modCommandsLibrary:HookChatCommand("minesweeper", {
		Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;
		Description = [[Minesweeper commands.
		/minesweeper start [seed]
		/minesweeper reveal
        /minesweeper click x y
		]];

		RequiredArgs = 0;
		UsageInfo = "/minesweeper cmd";
		Function = function(speaker, args)
            local profile = shared.modProfile:Get(speaker);
            local playerCache = profile.Cache;

			local actionId = args[1];

			if actionId == "start" then
                local seed = args[2];

                local minesweeper = Minesweeper.new();
                playerCache.MinesweeperGame = minesweeper;

                minesweeper:Start(seed);

                shared.Notify(speaker, `Minesweeper started!`, "Inform");

            elseif actionId == "reveal" then
                if playerCache.MinesweeperGame == nil then
                    shared.Notify(speaker, `No active minesweeper game.`, "Negative");
    
                    return;
                end

                local minesweeper = playerCache.MinesweeperGame;

                shared.Notify(speaker, `Minesweeper reveals!`, "Inform");
                shared.Notify(speaker, `{minesweeper:StringifyMinefield(1)}`, "Inform");

            elseif actionId == "click" then
                if playerCache.MinesweeperGame == nil then
                    shared.Notify(speaker, `No active minesweeper game.`, "Negative");
    
                    return;
                end

                local x = args[2] or 1;
                local y = args[3] or 1;

                local minesweeper = playerCache.MinesweeperGame;

                local clickedOnMine = minesweeper:Uncover(x, y);

                shared.Notify(speaker, `Minesweeper clicked!`, "Inform");
                shared.Notify(speaker, `{minesweeper:StringifyMinefield()}`, "Inform");
                if clickedOnMine then
                    shared.Notify(speaker, `You clicked a mine!`, "Inform");
                end
                
			end


			return true;
		end;
	});
end)

return Minesweeper;