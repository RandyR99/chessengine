interface = {}

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

local function ram_block(tag, offset, len)
	local share = machine.memory.shares[tag]
	local s = ""
	for i = 0, len - 1 do
		s = s .. string.char(share:read_u8(offset + i))
	end
	return s
end

interface.level = "1"
interface.cur_level = nil
interface.score = "0.00"
interface.depth = "0"
interface.pv = ""

function interface.get_module()
	return "Novag Super Nova"
end

function interface.get_author()
	return "David Kittinger"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local level = tonumber(interface.level)
	local y = (level - 1) % 8 + 1
	local x = (level - y) / 8 + 1
	send_input(":IN.0", 0x04, 0.5) -- Set Level
	sb_press_square(":board", 1, x, y)
	send_input(":IN.1", 0x01, 0.5) -- Go
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	send_input(":IN.1", 0x80, 0.5) -- New Game
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = "1"
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.0", 0x40, 0.5) -- Sound
		send_input(":IN.1", 0x20, 0.5) -- Verify/Setup
		send_input(":IN.1", 0x20, 0.5) -- Verify/Setup
		send_input(":IN.1", 0x08, 0.5) -- Clear Board
		machine.video.throttled = throttled_state
		return (":board")
	else
		local piece = 7
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if p * piece < 0 then
						send_input(":IN.1", 0x10, 0.5) -- Color
					end
					if math.abs(p) ~= math.abs(piece) then
						send_input(":IN.0", 0x80 >> (math.abs(p) - 1), 0.5)
					end
					sb_press_square(":board", 1, x, 9 - y)
					piece = p
				end
			end
		end
		send_input(":IN.1", 0x01, 0.5) -- Go
		if mode < 0 then
			send_input(":IN.1", 0x10, 0.5) -- Color
		end
		send_input(":IN.0", 0x40, 0.5) -- Sound
		send_input(":IN.1", 0x08, 0.5) -- Clear
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game()
	send_input(":IN.0", 0x80, 0.5) -- Referee
	emu.wait(0.5)
end

function interface.start_play(init)
	send_input(":IN.1", 0x01, 0.5) -- Go
end

function interface.stop_play()
	send_input(":IN.1", 0x01, 0.5) -- Go
end

function interface.is_selected(x, y)
	local xval = output_value("1." .. tostring(x - 1)) ~= 0
	local yval = output_value("0." .. tostring(8 - y)) ~= 0
	return xval and yval
end

-- the board needs a square held for more than 350 ms (MAME driver set_delay)
function interface.select_piece(x, y, event)
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "string", "Level", "1" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = value:upper():match("^%s*(.-)%s*$"):gsub("%s%s+", " ") -- trim
		local n = tonumber(level)
		if (n ~= nil and n >= 1 and n <= 48) then
			level = n
		else
			local tmp = level:sub(1,2)
			if     (tmp == "TR") then tmp = 0
			elseif (tmp == "FT") then tmp = 1
			elseif (tmp == "SD") then tmp = 2
			elseif (tmp == "FD") then tmp = 3
			elseif (tmp == "AN") then tmp = 4
			elseif (tmp == "EA") then tmp = 5
			else return
			end
			n = tonumber(level:sub(3, 4))
			if (n == nil or n < 1 or n > 8) then return end
			level = tmp * 8 + n
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	local map = {"s0.1", "s1.1", "s2.1", "s3.0", "s2.0", "s0.0", "s1.0"}
	local dig = 0x00
	for i = 1, 7 do
		if (output_value(map[i]) ~= 0) then
			dig = dig | (1 << (i - 1))
		end
	end
	if     (dig == 0x67) then return 'q'
	elseif (dig == 0x50) then return 'r'
	elseif (dig == 0x7c) then return 'b'
	elseif (dig == 0x54) then return 'n'
	end
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	if     (piece == "q") then send_input(":IN.0", 0x40, 1)
	elseif (piece == "r") then send_input(":IN.0", 0x20, 1)
	elseif (piece == "b") then send_input(":IN.0", 0x10, 1)
	elseif (piece == "n") then send_input(":IN.0", 0x08, 1)
	end
end

function interface.show_info(on)
	if on then
		local ddram = ram_block(":maincpu:internal_ram", 0x82, 0x05)
		if (digit_ascii(ddram:byte(1)) .. digit_ascii(ddram:byte(2))) == "d " then
			interface.depth = digit_ascii(ddram:byte(3)) .. digit_ascii(ddram:byte(4))
		elseif digit_ascii(ddram:byte(1)) == " " or digit_ascii(ddram:byte(1)) == "-" then
			interface.score = (digit_ascii(ddram:byte(1)) .. digit_ascii(ddram:byte(2)) .. digit_ascii(ddram:byte(3)) .. digit_ascii(ddram:byte(4))):gsub(" ","")
		elseif digit_ascii(ddram:byte(1)) == "a" or digit_ascii(ddram:byte(1)) == "b" or digit_ascii(ddram:byte(1)) == "c" or digit_ascii(ddram:byte(1)) == "d" or digit_ascii(ddram:byte(1)) == "e" or digit_ascii(ddram:byte(1)) == "f" or digit_ascii(ddram:byte(1)) == "g" or digit_ascii(ddram:byte(1)) == "h" then
			interface.pv = digit_ascii(ddram:byte(1)) .. digit_ascii(ddram:byte(2)) .. digit_ascii(ddram:byte(3)) .. digit_ascii(ddram:byte(4))
		end
		return "info score cp " .. interface.score .. " depth " .. interface.depth .. " pv " .. interface.pv
	end
end

function digit_ascii(digit)
	if     digit == nil                     then return (" ")
	elseif digit == 215 or digit == 215 + 8 then return ("0")
	elseif digit == 6 or digit == 6 + 8     then return ("1")
	elseif digit == 227 or digit == 227 + 8 then return ("2")
	elseif digit == 167 or digit == 167 + 8 then return ("3")
	elseif digit == 54 or digit == 54 + 8   then return ("4")
	elseif digit == 181 or digit == 181 + 8 then return ("5")
	elseif digit == 253 - 8 or digit == 253 then return ("6")
	elseif digit == 15 - 8 or digit == 15   then return ("7")
	elseif digit == 255 - 8 or digit == 255 then return ("8")
	elseif digit == 183 or digit == 183 + 8 then return ("9")
	elseif digit == 32 or digit == 40       then return ("-")
	elseif digit == 227 - 8 or digit == 227 then return ("a")
	elseif digit == 127 - 8 or digit == 127 then return ("A")
	elseif digit == 100 or digit == 100 + 8 then return ("n")
	elseif digit == 161 or digit == 161 + 8 then return ("on")
	elseif digit == 182 or digit == 182 + 8 then return ("Y")
	elseif digit == 252 - 8 or digit == 252 then return ("b")
	elseif digit == 217 - 8 or digit == 217 then return ("c")
	elseif digit == 238 - 8 or digit == 238 then return ("d")
	elseif digit == 249 - 8 or digit == 249 then return ("e")
	elseif digit == 121 - 8 or digit == 121 then return ("f")
	elseif digit == 221 - 8 or digit == 221 then return ("g")
	elseif digit == 124 - 8 or digit == 124 then return ("h")
	elseif digit == 0 or digit == 8         then return (" ")
	elseif digit == 104 - 8 or digit == 104 then return ("r")
	else
	    return (" hex" .. (digit) .. "?")
	end
end

return interface
