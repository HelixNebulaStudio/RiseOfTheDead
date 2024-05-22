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

return RichFormatter;