-- Reader for the rotating search display of the Novag Sapphire and Diamond family. While the machine calculates,
-- the LCD shows each page for 2 s without any key press (Sapphire II manual, INFO key section):
--   d7d5 | E2E3 | b8c6 | 0069 | d 08 | 2122 | 0013
--   next 3 plies, score in centipawns, depth, moves left and total, time
-- The moves left page can read like a score (" 830" = 8 of 30), so a score only counts right before a depth page.
local lcd = {}

lcd.digits4 = {
	{ "s0.1", "s1.1", "s2.1", "s3.0", "s2.0", "s0.0", "s1.0" },
	{ "s0.3", "s1.3", "s2.3", "s3.2", "s2.2", "s0.2", "s1.2" },
	{ "s0.5", "s1.5", "s2.5", "s3.4", "s2.4", "s0.4", "s1.4" },
	{ "s0.7", "s1.7", "s2.7", "s3.6", "s2.6", "s0.6", "s1.6" },
}

-- the first 2 of the 6 digits are for the clock and the move number, and stay blank on the rotating pages
lcd.digits6 = {
	{ "s0.2", "s1.2", "s3.2", "s3.0", "s2.0", "s1.0", "s2.1" },
	{ "s0.3", "s1.4", "s3.4", "s3.3", "s2.3", "s1.3", "s2.4" },
	{ "s0.6", "s1.7", "s3.7", "s3.6", "s2.6", "s1.6", "s2.7" },
	{ "s0.8", "s1.9", "s3.9", "s3.8", "s2.8", "s1.8", "s2.9" },
	{ "s0.11", "s1.12", "s3.12", "s3.11", "s2.11", "s1.11", "s2.12" },
	{ "s0.13", "s1.14", "s3.14", "s3.13", "s2.13", "s1.13", "s2.14" },
}

-- Zircon II: same rotation on the right LCD panel, outputs digit4-digit7
lcd.digits_zircon2 = { 4, 5, 6, 7 }

local chars = {
	[0x00] = " ", [0x40] = "-",
	[0x3f] = "0", [0x06] = "1", [0x5b] = "2", [0x4f] = "3", [0x66] = "4",
	[0x6d] = "5", [0x7d] = "6", [0x07] = "7", [0x7f] = "8", [0x6f] = "9", [0x67] = "9",
	[0x77] = "a", [0x5f] = "a", [0x7c] = "b", [0x58] = "c", [0x39] = "c", [0x5e] = "d",
	[0x79] = "e", [0x7b] = "e", [0x71] = "f", [0x3d] = "g", [0x74] = "h", [0x76] = "h",
}

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

local function page_text(digits)
	local text = ""
	for _, segments in ipairs(digits) do
		local value = 0
		if tonumber(segments) then -- (type() is not in the interface environment)
			value = output_value("digit" .. segments) & 0x7f -- the driver gives whole 7-segment digits
		else
			for i, name in ipairs(segments) do
				if output_value(name) ~= 0 then
					value = value | (1 << (i - 1))
				end
			end
		end
		text = text .. (chars[value] or "?")
	end
	if #text == 6 then
		if text:sub(1, 2) == " -" then
			return text:sub(2) -- a negative score uses a 5th digit: " -0961"
		elseif text:sub(1, 2) ~= "  " then
			return ""
		end
		text = text:sub(3)
	end
	return text
end

function lcd.reader(digits)
	local last_text, last_page
	local moves, moves_count, pending_score
	local score, depth, pv

	return function(on)
		if not on then
			last_text, last_page, moves, moves_count, pending_score = nil, nil, nil, 0, nil
			score, depth, pv = nil, nil, nil
			return nil
		end

		local text = page_text(digits)
		if text ~= last_text then
			last_text = text -- a page counts when it's still there at the next read: the LCD redraws digit by digit
			return { score = score, depth = depth, pv = pv }
		end
		if text == last_page then
			return { score = score, depth = depth, pv = pv }
		end

		local was_move = last_page ~= nil and last_page:match("^[a-h][1-8][a-h][1-8]$") ~= nil
		local sign, pawns = text:match("^([ %-%d])(%d%d%d)$")
		local negative = text:match("^%-(%d%d%d%d)$")
		local plies = text:match("^d (%d%d)$")
		if text:match("^[a-h][1-8][a-h][1-8]$") then
			if not was_move or moves == nil then
				moves, moves_count = text, 1
			elseif moves_count < 3 then
				moves, moves_count = moves .. " " .. text, moves_count + 1
			end
			pending_score = nil
		else
			if was_move and moves ~= nil then
				pv = moves
			end
			if plies then
				depth = tostring(tonumber(plies))
				score = pending_score or score
				pending_score = nil
			elseif negative then
				pending_score = tostring(-tonumber(negative))
			elseif pawns then
				local value = tonumber(pawns)
				if sign == "-" then
					value = -value
				elseif sign ~= " " then
					value = tonumber(sign) * 1000 + value
				end
				pending_score = tostring(value)
			else
				pending_score = nil
			end
		end
		last_page = text
		return { score = score, depth = depth, pv = pv }
	end
end

return lcd
