interface = load_interface("supercon")

interface.level = "a1"
interface.cur_level = nil
interface.pv = ""
interface.depth = "0"
interface.score = "0.00"

function interface.get_module()
	if machine.system.name == "cfortea" then
		return "Novag Constellation Forte"
	elseif machine.system.name == "cforteb" then
		return "Novag Constellation Forte v2"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "David Kittinger"
end

function interface.getdigit(n)
	emu.wait(0.5)
	local ddram = emu.item(machine.devices[':maincpu'].items['0/:nvram'])
	local d = ddram:read(0xc20 + n) & 0x7f
	return d
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local level = interface.level
	local cols_idx = {a = 1, b = 2, c = 3, d = 4, e = 5, f = 6, g = 7, h = 8}
	local x = cols_idx[level:sub(1, 1)]
	local y = level:sub(2, 2)
	send_input(":IN.2", 0x02, 0.5) -- Sound (off)
	send_input(":IN.6", 0x02, 0.5) -- Set Level
	sb_press_square(":board", 0.5, x, y)
	level = level:sub(4)
	for i = 1, level:len() do
		if (i == 1) then
			send_input(":IN.2", 0x01, 0.5) -- Time Control
		end
		local j = i % 9
		if (j == 0) then
			send_input(":IN.3", 0x01, 0.5) -- Flip Display
			send_input(":IN.2", 0x01, 0.5) -- Time Control
		elseif (j ~= 3 and j ~= 6) then
			local k = 0
			if (j == 1 or j == 4) then
				k = 0x04
			elseif (j == 2 or j == 5) then
				k = 0x05
			elseif (j == 7) then
				k = 0x06
			elseif (j == 8) then
				k = 0x07
			end
			local d = tonumber(level:sub(i, i)) - interface.getdigit(k)
			if (j == 7) then
				if (d > 3) then
					d = d - 6
				elseif (d < -3) then
					d = d + 6
				end
			else
				if (d > 5) then
					d = d - 10
				elseif (d < -5) then
					d = d + 10
				end
			end
			for n = 1, math.abs(d) do
				if (d > 0) then
					send_input(":IN.7", 0x01, 0.25) -- ->
				else
					send_input(":IN.7", 0x02, 0.25) -- <-
				end
			end
			send_input(":IN.6", 0x01, 0.5) -- Yes
		end
	end
	send_input(":IN.7", 0x01, 0.5) -- Go
	send_input(":IN.2", 0x02, 0.5) -- Sound (on)
	send_input(":IN.6", 0x02, 0.5) -- Set Level
	send_input(":IN.7", 0x01, 0.5) -- Go
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	emu.wait(2)
	send_input(":IN.0", 0x01, 1) -- New Game
	emu.wait(5)
	interface.cur_level = "a1"
	interface.setlevel()
	send_input(":IN.6", 0x02, 0.5) -- Set Level
	send_input(":IN.2", 0x02, 0.5) -- Depth Search
	emu.wait(0.5)
	local ddram = emu.item(machine.devices[':maincpu'].items['0/:nvram'])
	if digit_ascii(ddram:read(0xc20 + 8)) == "f" then
		send_input(":IN.2", 0x02, 0.5) -- depth Search
	end
	send_input(":IN.7", 0x01, 0.5) -- Go
	machine.video.throttled = throttled_state
end

function setpiece(n)
	if     (n == 1) then send_input(":IN.0", 0x02, 0.5) -- K
	elseif (n == 2) then send_input(":IN.1", 0x02, 0.5) -- Q
	elseif (n == 3) then send_input(":IN.4", 0x02, 0.5) -- R
	elseif (n == 4) then send_input(":IN.2", 0x02, 0.5) -- B
	elseif (n == 5) then send_input(":IN.3", 0x02, 0.5) -- N
	elseif (n == 6) then send_input(":IN.5", 0x02, 0.5) -- P
	end
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.2", 0x02, 0.5) -- Sound
		send_input(":IN.1", 0x01, 0.5) -- Verify/Setup
		send_input(":IN.1", 0x01, 0.5) -- Verify/Setup
		send_input(":IN.3", 0x01, 0.5) -- Clear Board
		machine.video.throttled = throttled_state
		return (":board")
	else
		local piece = 7
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x ,9 - y)
				if p ~= 0 then
					if p * piece < 0 then
						send_input(":IN.2", 0x01, 0.5) -- Change Color
					end
					if math.abs(p) ~= math.abs(piece) then
						setpiece(math.abs(p))
					end
					sb_press_square(":board", 0.5, x, 9-y)
					piece = p
				end
			end
		end
		send_input(":IN.7", 0x01, 0.5) -- GO
		send_input(":IN.2", 0x02, 0.5) -- Sound
		if mode == -1 then
			send_input(":IN.2", 0x01, 0.5) -- Change Color
			send_input(":IN.6", 0x01, 0.5) -- Yes
		else
			send_input(":IN.1", 0x01, 0.5) -- Verify/Setup
			send_input(":IN.7", 0x01, 0.5) -- Go
		end
	end
	machine.video.throttled = throttled_state
end

function interface.get_options()
	return {
		{ "string", "Level", "a1" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = value:lower():match("^%s*(.-)%s*$"):gsub("%s%s+", " ") -- trim
		local num = tonumber(level:sub(1, 2))
		if (num ~= nil and num >= 1 and num <= 16) then
			local mod = (num - 1) % 8 + 1
			local div = (num - mod) / 8 + 1
			level = string.char(div + 96) .. tostring(mod) .. level:sub(3)
		end
		if (level:match("^[ab][1-8]$") or level:match("^b8%s%d%d/%d%d:[0-5]%d$") or level:match("^b8%s%d%d/%d%d:[0-5]%d%s%d%d/%d%d:[0-5]%d$")) then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.get_promotion(x, y)
	local d8 = output:get_value("digit8")
	if     (d8 == 0x67) then return "q"
	elseif (d8 == 0x50) then return "r"
	elseif (d8 == 0x7c) then return "b"
	elseif (d8 == 0x54) then return "n"
	end
	return nil
end

function interface.show_pv_after_move_emu()
	interface.pv = ""
	interface.depth = 1
end

function interface.show_info(on)
	if on then
		local ddram = emu.item(machine.devices[':maincpu'].items['0/:nvram'])
		if digit_ascii(ddram:read(0xc20 + 0)) == "d" and ddram:read(0xc20 + 2) < 10 then
			interface.depth = digit_ascii(ddram:read(0xc20 + 1)) .. digit_ascii(ddram:read(0xc20 + 2)):gsub(" ", "")
		elseif digit_ascii(ddram:read(0xc20 + 5)) == " " or digit_ascii(ddram:read(0xc20 + 5)) == "-" then
			interface.pv = digit_ascii(ddram:read(0xc20 + 0)) .. digit_ascii(ddram:read(0xc20 + 1)) .. digit_ascii(ddram:read(0xc20 + 2)) .. digit_ascii(ddram:read(0xc20 + 3))
			interface.score = digit_ascii(ddram:read(0xc20 + 5)) .. digit_ascii(ddram:read(0xc20 + 6)) .. digit_ascii(ddram:read(0xc20 + 7)) .. digit_ascii(ddram:read(0xc20 + 8)) .. digit_ascii(ddram:read(0xc20 + 9)):gsub(" ", "")
		end
		return "info score cp " .. interface.score .. " depth " .. interface.depth .. " pv " .. interface.pv
	end
end

function digit_ascii(digit)
	if     (digit == 10)  then return "-"
	elseif (digit == 11)  then return "_"
	elseif (digit == 0) or (digit == 128) then return "0"
	elseif (digit == 1) or (digit == 129) then return "1"
	elseif (digit == 2) or (digit == 130) then return "2"
	elseif (digit == 3) or (digit == 131) then return "3"
	elseif (digit == 4) or (digit == 132) then return "4"
	elseif (digit == 5) or (digit == 133) then return "5"
	elseif (digit == 6) or (digit == 134) then return "6"
	elseif (digit == 7) or (digit == 135) then return "7"
	elseif (digit == 8) or (digit == 136) then return "8"
	elseif (digit == 9) or (digit == 137) then return "9"
	elseif (digit == 32)  then return " "
	elseif (digit == 97)  then return "a"
	elseif (digit == 98)  then return "b"
	elseif (digit == 99)  then return "c"
	elseif (digit == 100) then return "d"
	elseif (digit == 101) then return "e"
	elseif (digit == 102) then return "f"
	elseif (digit == 103) then return "g"
	elseif (digit == 104) then return "h"
	elseif (digit == 105) then return "i"
	elseif (digit == 106) then return "j"
	elseif (digit == 107) then return "k"
	elseif (digit == 108) then return "l"
	elseif (digit == 109) then return "m"
	elseif (digit == 110) then return "n"
	elseif (digit == 111) then return "o"
	elseif (digit == 113) then return "p"
	elseif (digit == 114) then return "r"
	elseif (digit == 115) then return "s"
	elseif (digit == 116) then return "t"
	elseif (digit == 117) then return "u"
	elseif (digit == 121) then return "y"
	elseif (digit == 240) then return "p"
	end
end

return interface
