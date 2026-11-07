-- Rotating Display of the Saitek GK 2000 family (Centurion manual 5.2): once set, the LCD cycles the chosen pages
-- on its own, only while the machine thinks, so nothing has to be pressed during a search:
--   d7-d5 | C1-b2 | C7-C5 | G1-F3 | + 0.1 | 6_ 1
--   the predicted line, the evaluation in pawns with a positive value when White is ahead, depth and moves searched
local rotating = {}

-- digits from left to right, segments a to g (gk2000.svg)
local digits = {
	{ "s0.23", "s0.2", "s1.2", "s1.1", "s0.1", "s1.23", "s0.0" },
	{ "s0.19", "s0.4", "s1.4", "s1.3", "s0.3", "s1.20", "s0.20" },
	{ "s0.18", "s0.7", "s1.7", "s1.6", "s0.6", "s1.18", "s0.5" },
	{ "s0.14", "s0.9", "s1.9", "s1.8", "s0.8", "s1.15", "s0.15" },
	{ "s0.12", "s0.11", "s1.11", "s1.10", "s0.10", "s1.13", "s0.13" },
}

local chars = {
	[0x00] = " ", [0x40] = "-", [0x08] = "_",
	[0x3f] = "0", [0x06] = "1", [0x5b] = "2", [0x4f] = "3", [0x66] = "4",
	[0x6d] = "5", [0x7d] = "6", [0x07] = "7", [0x7f] = "8", [0x6f] = "9",
	[0x77] = "a", [0x7c] = "b", [0x39] = "c", [0x58] = "c", [0x5e] = "d",
	[0x79] = "e", [0x71] = "f", [0x3d] = "g", [0x76] = "h", [0x74] = "h",
}

-- GK 2000 family wiring; Mephisto MM VI changes it
rotating.lcd_device = ":"
rotating.board = ":board"
rotating.option = { ":IN.0", 0x08 }
rotating.clear = { ":IN.0", 0x40 }
rotating.enter = { ":IN.0", 0x80 }
rotating.next = { ":IN.1", 0x80 } -- BLACK/>

local function output_value(name)
	local out = machine.devices[rotating.lcd_device]:output(name)
	return out ~= nil and out:get() or 0
end

local function page_text()
	local text = ""
	for _, segments in ipairs(digits) do
		local value = 0
		for i, name in ipairs(segments) do
			if output_value(name) ~= 0 then
				value = value | (1 << (i - 1))
			end
		end
		text = text .. (chars[value] or "?")
	end
	return text
end

-- on MM VI the moves on the rotating pages light the LEDs too. A played move differs: it shows the piece on the LCD, or
-- when it doesn't, it stays there, while a page is gone after a second
function rotating.move_settled()
	for _, name in ipairs({ "s1.12", "s1.14", "s1.16", "s1.17", "s1.19", "s1.21" }) do
		if output_value(name) ~= 0 then
			return true
		end
	end
	local text = page_text()
	local now = machine.time:as_double()
	if text ~= rotating.settled_text then
		rotating.settled_text, rotating.settled_since = text, now
	end
	return now - rotating.settled_since >= 2.5
end

-- the Rotating Display options: A3-D3 the predicted line, E3 the evaluation, F3 the depth. They are one OPTION further
-- on some models, where the option squares don't answer either: there ENTER switches the option and > goes to the next
function rotating.select_pages(by_keys)
	send_input(rotating.option[1], rotating.option[2], 0.5)
	send_input(rotating.option[1], rotating.option[2], 0.5)
	if by_keys then
		send_input(rotating.option[1], rotating.option[2], 0.5)
	end
	for x = 1, 6 do
		if by_keys then
			send_input(rotating.enter[1], rotating.enter[2], 0.5)
			send_input(rotating.next[1], rotating.next[2], 0.5)
		else
			sb_press_square(rotating.board, 0.5, x, 3)
		end
	end
	send_input(rotating.clear[1], rotating.clear[2], 0.5)
end

function rotating.show_info(on, color)
	if not on then
		rotating.last_text, rotating.last_page, rotating.moves = nil, nil, nil
		rotating.score, rotating.depth, rotating.pv = nil, nil, nil
		return nil
	end

	-- a page counts when it's still there at the next read: the LCD redraws digit by digit
	local text = page_text()
	if text == rotating.last_text and text ~= rotating.last_page then
		local from, to = text:match("^([a-h][1-8])%-([a-h][1-8])$")
		local was_move = rotating.last_page ~= nil and rotating.last_page:match("^[a-h][1-8]%-[a-h][1-8]$") ~= nil
		if from then
			rotating.moves = (was_move and rotating.moves) and (rotating.moves .. " " .. from .. to) or (from .. to)
		else
			if was_move and rotating.moves then
				rotating.pv = rotating.moves
			end
			rotating.moves = nil
			local plies = text:match("^ ?(%d+)_")
			local tenths = text:match("^[%- ]%s*(%d+)%s*$")
			if plies then
				rotating.depth = plies
			elseif tenths then
				local white = tonumber(tenths) * 10 -- the extra bar of the sign makes it a +
				if text:sub(1, 1) == "-" and output_value("s1.0") == 0 then
					white = -white
				end
				rotating.score = tostring(color == "B" and -white or white)
			end
		end
		rotating.last_page = text
	end
	rotating.last_text = text
	return { score = rotating.score, depth = rotating.depth, pv = rotating.pv }
end

return rotating
