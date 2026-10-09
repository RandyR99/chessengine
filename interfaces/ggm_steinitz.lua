interface = {}

interface.turn = true
interface.color = "B"
interface.level = "1"
interface.cur_level = nil
local computing
interface.edit = false
interface.Ticker = 0

-- Display digit as a 14seg value (0 when the output does not exist)
local function digit(n)
	local node = machine.devices[":"]:output("digit" .. n)
	return node and node:get() or 0
end

function interface.get_module()
	return "GGM Steinitz Edition"
end

function interface.get_author()
	return "Larry Atkin"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.3", 0x01, 0.25) -- LEVEL
	emu.wait(0.25)
	local level = interface.level
	if (level:sub(1,2) == "10") then
		send_input(":IN.2", 0x08, 0.25) -- TIME
		level = level:sub(3)
	end
	local k = 0
	for i = 1, level:len() do
		local d = level:sub(i,i)
		if (d == " " or d == "/") then
			if (k == 5) then
				break
			end
			send_input(":IN.3", 0x08, 0.25) -- TIMING
			k = k + 1
		elseif (string.match(d,"%d")) then
			if (tonumber(d) <= 4) then
				send_input(":IN.0", 1 << tonumber(d), 0.5)
			elseif (tonumber(d) <= 9) then
				send_input(":IN.1", 1 << tonumber(d - 5), 0.5)
			end
		end
	end
	send_input(":IN.3", 0x10, 0.25) -- ENTER
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	interface.turn = true
	interface.color = "B"
	emu.wait(3)
	machine.video.throttled = throttled_state
	interface.cur_level = "1"
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		return ("")
	else
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		local piece = 7
		for y = 1, 8 do
			send_input(":IN.2", 0x04, 0.5) -- RANK
			send_input(":IN.2", 0x10, 0.5) -- CE
			for x = 1, 8 do
				local p = get_piece_id(x, y)
				if p == 0 then
					send_input(":IN.2", 0x01, 0.5) -- [-]
				else
					if p * piece < 0 then
						send_input(":IN.2", 0x02, 0.5) -- B/W
					end
					emu.wait(0.5)
					interface.send_pos(7 - math.abs(p))
					piece = p
				end
			end
		end
		if mode * piece < 0 then
			send_input(":IN.2", 0x02, 0.5) -- B/W
		end
		if mode == 1 then
			interface.color = "B"
		else
			interface.color = "W"
		end
		send_input(":IN.3", 0x10, 0.5) -- ENTER
		machine.video.throttled = throttled_state
	end
end

function interface.edit_game(on)
	interface.edit = on
end

function interface.start_play(init)
	send_input(":IN.2", 0x02, 0.5) -- B/W
	if (interface.color == "W") then
		interface.color = "B"
	else
		interface.color = "W"
	end
	emu.wait(0.25)
	interface.turn = false
end

function interface.stop_play()
	if (not interface.turn) then
		send_input(":IN.3", 0x02, 0.5) -- HALT
		emu.wait(0.25)
	end
end

function interface.is_selected(x, y)
	if (x == 1 and y == 1) then
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		computing = false
		for i = 1, 4 do
			if (digit(7) == 0) then
				computing = true
				machine.video.throttled = throttled_state
				return false
			elseif (i < 4) then
				emu.wait(0.25)
			end
		end
		machine.video.throttled = throttled_state
	elseif (computing) then
		return false
	end
	local xval = { 0x0f7, 0x3cf, 0x039, 0x30f, 0x0f9, 0x0f1, 0x0bd, 0x0f6 }
	local yval = { 0x300, 0x0db, 0x0cf, 0x0e6, 0x0ed, 0x0fd, 0x007, 0x0ff }
	local d0 = digit(7)
	local d1 = digit(6)
	local d2 = digit(5)
	local d3 = digit(4)
	local d4 = digit(3)
	return ((xval[x] == d0 and yval[y] == d1) or (xval[x] == d3 and yval[y] == d4))
end

function interface.send_pos(p)
	if     (p == 1)	then send_input(":IN.0", 0x02, 0.5)
	elseif (p == 2)	then send_input(":IN.0", 0x04, 0.5)
	elseif (p == 3)	then send_input(":IN.0", 0x08, 0.5)
	elseif (p == 4)	then send_input(":IN.0", 0x10, 0.5)
	elseif (p == 5)	then send_input(":IN.1", 0x01, 0.5)
	elseif (p == 6)	then send_input(":IN.1", 0x02, 0.5)
	elseif (p == 7)	then send_input(":IN.1", 0x04, 0.5)
	elseif (p == 8)	then send_input(":IN.1", 0x08, 0.5)
	end
end

function interface.select_piece(x, y, event)
	if (event ~= "capture" and event ~= "get_castling" and event ~= "put_castling" and event ~= "en_passant") then
		if (interface.turn) then
			interface.send_pos(x)
			interface.send_pos(y)
		end
		if (event == "put") then
			if interface.edit == true then
				send_input(":IN.2", 0x02, 0.5) -- B/W
			else
				if (interface.turn) then
					send_input(":IN.3", 0x10, 0.5) -- ENTER
				end
				interface.turn = not interface.turn
			end
			emu.wait(0.25)
		end
	end
end

function interface.get_options()
	return {
		{ "string", "Level", "1" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = value:match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		if (level:sub(1,3) ~= "10 ") then
			level = tonumber(level)
			if (level == nil or level < 0 or level > 10) then
				return
			end
			level = tostring(level)
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	return 'q'	-- engine always promotes to Queen
end

function interface.promote(x, y, piece)
	promotion_error(piece)
	-- TODO
end

local function digit_ascii(value)
	if     value == nil then return " "
	elseif value == 0   then return " "
	elseif value == 192 then return "-"
	elseif value == 63  then return "0"
	elseif value == 191 then return "0"
	elseif value == 6   then return "1"
	elseif value == 134 then return "1"
	elseif value == 768 then return "1"
	elseif value == 91  then return "2"
	elseif value == 219 then return "2"
	elseif value == 79  then return "3"
	elseif value == 207 then return "3"
	elseif value == 102 then return "4"
	elseif value == 230 then return "4"
	elseif value == 109 then return "5"
	elseif value == 237 then return "5"
	elseif value == 125 then return "6"
	elseif value == 253 then return "6"
	elseif value == 7   then return "7"
	elseif value == 135 then return "7"
	elseif value == 127 then return "8"
	elseif value == 255 then return "8"
	elseif value == 111 then return "9"
	elseif value == 239 then return "9"
	elseif value == 55  then return "n"
	elseif value == 247 then return "a"
	elseif value == 975 then return "b"
	elseif value == 57  then return "c"
	elseif value == 783 then return "d"
	elseif value == 121 then return "e"
	elseif value == 249 then return "e"
	elseif value == 241 then return "f"
	elseif value == 189 then return "g"
	elseif value == 246 then return "h"
	elseif value == 8   then return "_"
	elseif value == 56  then return "l"
	elseif value == 83  then return "?"
	elseif value == 115 then return "p"
	elseif value == 80  then return "r"
	elseif value == 48  then return "i"
	elseif value == 62  then return "u"
	elseif value == 49  then return "t"
	elseif value == 110 then return "y"
	else                     return ""
	end
end

function interface.show_info(on)
    if on and interface.Ticker == 0 then
		local depth = 0
		local score = 0
		send_input(":IN.3", 0x01, 0.25) -- LEVEL
		emu.wait(0.5)
		local d1 = digit(6)
		local d6 = digit(1)
		local d7 = digit(0)
		if digit_ascii(d1) ~= "e" then
			interface.Ticker = 1
			send_input(":IN.3", 0x10, 0.25) -- ENTER
			return
		end
		depth = digit_ascii(d6) .. digit_ascii(d7)
		send_input(":IN.3", 0x04, 0.25) -- score
		emu.wait(0.5)
		local d0 = digit(7)
		local d4, d5
		d4 = digit(3)
		d5 = digit(2)
		d6 = digit(1)
		d7 = digit(0)
		if digit_ascii(d0) ~= "5" then
			interface.Ticker = 1
			send_input(":IN.3", 0x10, 0.25) -- ENTER
			return
		end
		score = digit_ascii(d4) .. digit_ascii(d5) .. digit_ascii(d6) .. digit_ascii(d7)
		send_input(":IN.3", 0x10, 0.5) -- ENTER
		emu.wait(0.6)
		d0 = digit(7)
		d1 = digit(6)
		local d3 = digit(4)
		d4 = digit(3)
		interface.Ticker = 1
		return "info score cp " .. score .. " depth " .. depth .. " pv " .. digit_ascii(d0) .. digit_ascii(d1) .. digit_ascii(d3) .. digit_ascii(d4)
	end
	interface.Ticker = interface.Ticker + 1
	if interface.Ticker == 4 then
		interface.Ticker = 0
	end
end

return interface
