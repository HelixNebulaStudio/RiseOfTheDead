local RichFormatter = {};

local h2O, h2C = '<b><font size="20">', '</font></b>';
local h3O, h3C = '<b><font size="16">', '</font></b>';

RichFormatter.Headers = {
	H2O=h2O;
	H2C=h2C;
	H3O=h3O;
	H3C=h3C;
};

function RichFormatter.H2Text(text)
	return h2O..tostring(text)..h2C;
end

function RichFormatter.H3Text(text)
	return h3O..tostring(text)..h3C;
end

local color = Color3.fromRGB(89, 163, 89);
local goldPremiumFont = '<font color="rgb(255, 205, 79)">';
local perksColor = '<font color="rgb(135, 169, 255)">'
local failFont = '<font color="rgb(163, 89, 89)">';
local successFont = '<font color="rgb(89, 163, 89)">';

function RichFormatter.GoldText(text)
	return goldPremiumFont.. text .. "</font>";
end

function RichFormatter.SuccessText(text)
	return successFont.. text .. "</font>";
end

function RichFormatter.FailText(text)
	return failFont.. text .. "</font>";
end

function RichFormatter.ColorRobuxText(text)
	return '<font color="rgb(45, 104, 63)">'..text..'</font>';
end

function RichFormatter.ColorPremiumText(text)
	return '<font color="rgb(185, 139, 0)">'..text..'</font>';
end;

function RichFormatter.ColorBoolText(text)
	text = tostring(text);
	if text:lower() == "true" then
		return '<font color="rgb(0,128,255)">'..text..'</font>';
	elseif text:lower() == "false" then
		return '<font color="rgb(255,102,102)">'..text..'</font>';
	end
	return text;
end

function RichFormatter.ColorStringText(text)
	return '<font color="rgb(218, 142, 117)">'..text..'</font>';
end

function RichFormatter.ColorNumberText(text)
	return '<font color="rgb(122, 194, 143)">'..text..'</font>';
end

function RichFormatter.RichFontSize(text, size)
	return '<font size="'..size..'">'.. text ..'</font>';
end

function RichFormatter.Color(color, text)
	return `<font color="#{color}">{text}</font>`;
end

function RichFormatter.ColorCommentText(text)
	return '<font color="#2b4f1b">'..text..'</font>';
end

function RichFormatter.SanitizeRichText(text)
	text = string.gsub(text,"&","&amp;");
	text = string.gsub(text,"<","&lt;");
	text = string.gsub(text,">","&gt;");
	text = string.gsub(text,'"',"&quot;");
	text = string.gsub(text,"'","&apos;");

	return text;
end

function RichFormatter.UnsanitizeRichText(text, senderName)
	local pattern = "(.-)&lt;([^%s]-)(.-)&gt;(.-)&lt;/(%2)&gt;(.-)";
	local gmatch = string.gmatch(text, pattern);

	local embeds = {};
	local buildStr = ``;

	for a=1, 8 do
		local contents = {gmatch()};
		if #contents <= 0 then
			if a == 1 then
				return text;
			end
			break; 
		end;
		
		local preText = contents[1];
		local openTag = contents[2];
		local attTag = contents[3];
		local content = contents[4];
		local closeTag = contents[5];
		local postText = contents[6];

		local attGMatch = string.gmatch(attTag, `%s-([^%s]+)=&quot;(.-)&quot;`);
		if openTag == "font" then
			local newAtt = ``;
			for b=1, 4 do
				local attKey, attVal = attGMatch();
				if attKey == nil or attVal == nil then break end;

				if attKey == "color" then
					if string.match(attVal, `#%x%x%x%x%x%x`) then
						newAtt = newAtt..` {attKey}='{attVal}'`;
					elseif string.match(attVal, `rgb%((%d+),(%d+),(%d+)%)`) then
						local rgb = string.gsub(attVal, `rgb%((%d+),(%d+),(%d+)%)`, function(r, g, b)
							return `rgb({math.clamp(r or 255, 0, 255)},{math.clamp(g or 255, 0, 255)},{math.clamp(b or 255, 0, 255)})`
						end);
						newAtt = newAtt..` {attKey}='{rgb}'`;
					end

				elseif attKey == "size" then
					if tonumber(attVal) then
						newAtt = newAtt..` {attKey}='{math.clamp(attVal, 0, 32)}'`;
					end

				elseif attKey == "face" then
					for i, enum in pairs(Enum.Font:GetEnumItems()) do
						if string.lower(attKey) == string.lower(enum.Name) then
							newAtt = newAtt..` {attKey}='{enum.Name}'`;
							break;
						end
					end
				end
			end

			attTag = newAtt;

		else
			attTag = "";

		end

		content = RichFormatter.UnsanitizeRichText(content);

		local new = `{preText}<{openTag}{attTag}>{content}</{closeTag}>{postText}`;

		if openTag == "psst" and closeTag == "psst" then
			attTag = "";
			buildStr = buildStr..`{preText}<i><font size="9">{content}</font></i>{postText}`;

		elseif openTag == "yell" and closeTag == "yell" then
			attTag = "";
			buildStr = buildStr..`{preText}<b><font size="32">{content}</font></b>{postText}`;

		elseif openTag == "huh" and closeTag == "huh" then

			local splitContent = string.split(content, " ");
			for a=1, #splitContent do
				local fontEnum = Enum.Font:GetEnumItems();
				fontEnum = fontEnum[math.random(1, #fontEnum)];
				splitContent[a] = `<font face="{fontEnum.Name}">{splitContent[a]}</font>`
			end

			buildStr = buildStr..`{preText}{table.concat(splitContent, " ")}{postText}`;

		elseif openTag == "img" and closeTag == "img" then

			if content == "factionicon" then

			else
				local itemLib = require(game.ReplicatedStorage.Library.ItemsLibrary):Find(content);
				if itemLib and itemLib.Icon then
					table.insert(embeds, {
						Type="Image";
						Image=itemLib.Icon;
					});
				end

				local npcLib = require(game.ReplicatedStorage.BaseLibrary.NpcProfileLibrary):Find(content);
				if npcLib and npcLib.Avatar then
					table.insert(embeds, {
						Type="Image";
						Image=npcLib.Avatar;
					});
				end

			end
			buildStr = buildStr..`{preText}{postText}`;

		else
			buildStr = buildStr..new;

		end
	end
	
	return buildStr, embeds;
end

return RichFormatter;