local Base64Module = {}

-- Base64 character set
local base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/:"

-- Global variable for the encryption key
local encryptionKey = ""

-- Generate a random 8-bit key
local function generateRandomKey()
	local key = ""
	for i = 1, 8 do
		key = key..tostring(math.random(0, 1))
	end
	return key
end

-- Ensure the global encryption key is set correctly
if encryptionKey == "" then
	encryptionKey = generateRandomKey()

	print("New Key Generated: "..encryptionKey)
end

-- Function to perform XOR on two binary strings of equal length
local function xorBinary(bin1, bin2)
	if #bin1 ~= #bin2 then
		error("Binary strings must have the same length for XOR.")
	end

	local result = ""
	for i = 1, #bin1 do
		local bit1 = tonumber(bin1:sub(i, i))
		local bit2 = tonumber(bin2:sub(i, i))
		result = result..tostring((bit1 == bit2) and 0 or 1)
	end
	return result
end

-- Convert a number to an 8-bit binary string
local function toEightBitBinary(num)
	local result = ""
	for i = 7, 0, -1 do
		local bit = math.floor(num / 2^i) % 2
		result = result..bit
	end
	return result
end

-- Convert a number to a 6-bit binary string
local function toSixBitBinary(num)
	local result = ""
	for i = 5, 0, -1 do
		local bit = math.floor(num / 2^i) % 2
		result = result..bit
	end
	return result
end

function Base64Module.base64Encode(input, key)
	local localKey = key or encryptionKey

	if localKey == nil or #localKey ~= 8 then
		error("Invalid encryption key. Must be 8 bits long.")
	end

	local bitStream = ""

	-- Encoding logic with XOR
	for i = 1, #input do
		local charByte = input:byte(i)
		local binaryChar = toEightBitBinary(charByte)
		bitStream = bitStream..xorBinary(binaryChar, localKey)
	end

	-- Pad with zeros to ensure a multiple of 6 bits
	local padCount = (6 - (#bitStream % 6)) % 6
	bitStream = bitStream..string.rep("0", padCount)

	local output = ""
	-- Convert 6-bit segments to Base64 characters
	for i = 1, #bitStream, 6 do
		local segment = bitStream:sub(i, i + 5)
		local index = tonumber(segment, 2)
		if index then
			output = output..base64Chars:sub(index + 1, index + 1)
		else
			error("Invalid Base64 encoding segment: "..segment)
		end
	end

	-- Add padding characters for Base64 output
	if padCount == 2 then
		output = output.."=="
	elseif padCount == 4 then
		output = output.."="
	end

	return output
end

function Base64Module.base64Decode(encoded, key)
	local localKey = key or encryptionKey
	
	print(encoded)

	-- Ensure a valid 8-bit encryption key
	if localKey == nil or #localKey ~= 8 then
		error("Invalid encryption key. Must be 8 bits long.")
	end

	-- Remove padding characters and count padding
	local padCount = 0
	while encoded:sub(-1) == "=" do
		padCount = padCount + 1
		encoded = encoded:sub(1, -2)
	end

	local validatedEncoded = encoded

	local bitStream = ""
	-- Convert Base64 characters to binary
	for i = 1, #validatedEncoded do
		local char = validatedEncoded:sub(i, i)
		local index = base64Chars:find(char) - 1
		if index then
			bitStream = bitStream..toSixBitBinary(index)
		else
			error("Invalid Base64 character: "..char)
		end
	end

	-- Add padding bits to ensure a multiple of 8 bits
	if padCount > 0 then
		bitStream = bitStream..string.rep("00", padCount * 2)
	end
	-- Ensure the bit stream is a multiple of 8 bits
	if (#bitStream % 8) ~= 0 then
		print(bitStream)
		error("Invalid Base64 data, incomplete bit stream.")
	end
	local output = ""
	-- Convert each 8-bit segment back to characters
	for i = 1, #bitStream, 8 do
		local segment = bitStream:sub(i, i + 7)
		local decodedBinary = xorBinary(segment, localKey)
		local number = tonumber(decodedBinary, 2)
		output = output..string.char(number)
	end
	return output
end

Base64Module.enc_key = encryptionKey

return Base64Module