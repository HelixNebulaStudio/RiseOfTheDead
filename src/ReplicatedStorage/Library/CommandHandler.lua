local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local HttpService = game:GetService("HttpService");

local CommandHandler = {}

function CommandHandler.ProcessMessage(message)
	local splits = message:split(" ");
	
	for a=#splits, 1, -1 do
		if splits[a] == "" then
			table.remove(splits, a);
		end
	end
	
	if #splits > 0 and splits[1]:sub(1,1) == "/" then
		local cmd = table.remove(splits, 1);
		local argsRaw = splits;

		local joinArg = "";
		local function regroupArgs(inputArgs, openSymbol, closeSymbol)
			local args = {};
			
			local isOpen = false;
			for a=1, #inputArgs do
				local str = inputArgs[a];
				local len = #str;

				if isOpen then

					joinArg = joinArg.." "..str;

					if str:sub(len-(#closeSymbol-1), len) == closeSymbol then
						isOpen = false;
						table.insert(args, joinArg);
						joinArg = "";
					end

				elseif str:sub(1,#openSymbol) == openSymbol and str:sub(len-(#closeSymbol-1),len) ~= closeSymbol then
					isOpen = true;
					joinArg = str;

				else
					table.insert(args, inputArgs[a]);

				end
			end
			
			return args;
		end
		
		local args = regroupArgs(argsRaw, '"', '"');
		args = regroupArgs(args, "{", "}");
		args = regroupArgs(args, "[[", "]]");
		
		--local cacheArgs = {};
		--local joinArg = "";
		
		--local openQuote = false;
		--for a=1, #argsRaw do
		--	local str = argsRaw[a];
		--	local len = #str;
			
		--	if openQuote then
				
		--		joinArg = joinArg.." "..str;
				
		--		if str:sub(len,len) == '"' then
		--			openQuote = false;
		--			table.insert(cacheArgs, joinArg);
		--			joinArg = "";
		--		end
				
		--	elseif str:sub(1,1) == '"' and str:sub(len,len) ~= '"' then
		--		openQuote = true;
		--		joinArg = str;
				
		--	else
		--		table.insert(cacheArgs, argsRaw[a]);
				
		--	end
		--end
		
		--local args = {};
		
		--local openSqrBracket = false;
		--for a=1, #cacheArgs do
		--	local str = cacheArgs[a];
		--	local len = #str;
			
		--	if openSqrBracket then
				
		--		joinArg = joinArg.." "..str;
				
		--		if str:sub(len-1,len) == ']]' then
		--			openSqrBracket = false;
		--			table.insert(args, joinArg);
		--			joinArg = "";
		--		end
		--	elseif str:sub(1,2) == '[[' and str:sub(len-1,len) ~= ']]' then
		--		openSqrBracket = true;
		--		joinArg = str;
				
		--	else
		--		table.insert(args, cacheArgs[a]);
				
		--	end
		--end
		
		for a=1, #args do
			args[a] = CommandHandler.EvalString(args[a]);
		end
		
		return cmd, args;
	end
end

function CommandHandler.GetPlayerFromString(str, notifyPlayer)
	local matches = {};
	
	str = tostring(str);
	
	if #str > 0 then
		for _, player in pairs(game.Players:GetPlayers()) do
			if player.Name:lower():find(str:lower()) then
				table.insert(matches, player);

			elseif tostring(player.UserId) == str then
				table.insert(matches, player);

			end
			if player.Name:lower() == str:lower() then
				return player;
			end
		end
	end
	
	if #matches == 1 then
		return matches[1];
		
	elseif #matches <= 0 then
		if notifyPlayer then
			local namelist = {};
			for a=1, #matches do
				table.insert(namelist, matches[a].Name);
			end
			shared.Notify(notifyPlayer, "Found more than 1 similar names: "..table.concat(namelist, ", ")..".", "Negative");
		end
		
	elseif #matches > 1 then
		if notifyPlayer then
			shared.Notify(notifyPlayer, "Could not find player matching: ".. str, "Negative");
		end
		
	end
	return nil;
end

function CommandHandler.MatchName(name)
	name = tostring(name);
	local matches = {};
	
	if #name <= 0 then return matches end;
	
	for _, player in pairs(game.Players:GetPlayers()) do
		if player.Name:lower():find(name:lower()) then
			table.insert(matches, player);
		end
		if player.Name:lower() == name:lower() then
			matches = {player};
			break;
		end
	end
	
	return matches;
end

function CommandHandler.MatchStringFromList(str, list)
	str = tostring(str);
	local matches = {};

	if #str <= 0 then return matches end;
	
	for a=1, #list do
		if list[a]:lower():find(str:lower()) then
			table.insert(matches, list[a]);
		end
		if str:lower() == list[a]:lower() then
			matches = {str};
			break;
		end
	end
	
	return matches;
end

function CommandHandler.MatchStringFromDict(str, dict)
	str = tostring(str);
	local matches = {};
	for key, _ in pairs(dict) do
		if key:lower():find(str:lower()) then
			table.insert(matches, key);
		end
		if str:lower() == key:lower() then
			matches = {str};
			break;
		end
	end
	return matches;
end

local function trim(s)
	local from = s:match"^%s*()"
	return from > #s and "" or s:match(".*%S", from)
end

function CommandHandler.EvalString(str)
	if str == nil then return nil end;
	
	if string.lower(str) == "true" then
		return true;
		
	elseif string.lower(str) == "false" then
		return false;

	elseif string.lower(str) == "nil" or str == "" then
		return nil;
		
	elseif tonumber(str) then
		return tonumber(str);
		
	elseif str:sub(1,1) == '"' and str:sub(#str, #str) == '"' then
		return tostring(str:sub(2, #str-1));

	elseif str:sub(1,1) == '{' and str:sub(#str, #str) == '}' then
		local decode = nil;
		local s, e = pcall(function()
			decode = HttpService:JSONDecode(str:sub(1, #str));
		end)
		if not s then
			warn("EvalString>>  "..e);
		end
		return decode;
		
	elseif str:sub(1,2) == '[[' and str:sub(#str-1, #str) == ']]' then
		local decode = nil;
		local s, e = pcall(function()
			decode = HttpService:JSONDecode(str:sub(3, #str-2));
		end)
		if not s then
			warn("EvalString>>  "..e);
		end
		return decode;
	end
	
	return str;
end

function CommandHandler.ParseString(...)
	Debugger:Log("Using deprecated ParseString", debug.traceback());
	return CommandHandler.EvalString(...);
end

function CommandHandler.FilterSearchTag(searchDict, str)
	local r = {};
	local c = 0;
	
	for key, v in pairs(searchDict) do
		if key:lower():find(str:lower()) then
			r[key] = v;
			c = c+1;
		else
			for _, tag in pairs(v) do
				if tag:lower():find(str:lower()) then
					r[key] = v;
					c = c+1;
					break;
				end
			end
		end
	end
	return r, c;
end

function CommandHandler.FilterDict(dict, strList)
	local r = {};
	
	for a=1, #strList do
		local str = strList[a];
		for key, v in pairs(dict) do
			if key:lower():find(str:lower()) then
				r[key] = v;
			end
		end
	end
	return r;
end

function CommandHandler.FormList(t)
	t = t or {};
	local s = "";
	
	local function shortenTable(st,d)
		d = d or 1;
		if d >= 2 then return "..." end;
		
		local r = "";
		for k, v in pairs(st) do
			if typeof(v) == "table" then
				r = r.."[<b>"..k.."</b>]=".."{"..shortenTable(st, d+1).."} ";
			else
				r = r.."[<b>"..k.."</b>]="..tostring(v).." ";
			end
		end
		return r;
	end
	
	for k, v in pairs(t) do
		if typeof(v) == "table" then
			s = s.."\n    <b>"..k..":</b> "..shortenTable(v).."";
		else
			s = s.."\n    <b>"..k..":</b> "..tostring(v).."";
		end
	end
	
	if #s <= 0 then
		s = "Empty";
	end
	return s;
end

return CommandHandler;