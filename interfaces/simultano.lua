interface = {}

interface.invert = false
interface.level = "a3"
interface.cur_level = nil

function interface.get_module()
	if machine.system.name == "simultano" then
		return "Saitek Simultano"
	elseif machine.system.name == "simultanoa" then
		return "Saitek Simultano v2"
	elseif machine.system.name == "cc2150" then
		return "Chess Champion 2150"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Julio Kaplan & Craig Barnes"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local cols_idx = {a = 1, b = 2, c = 3, d = 4, e = 5, f = 6, g = 7, h = 8}
	local x = cols_idx[interface.level:sub(1,1)]
	local y = tonumber(interface.level:sub(2,2))
	send_input(":IN.0", 0x02, 1) -- Level
	emu.wait(0.5)
	local invert = interface.invert
	interface.invert = false
	local clevx = 0
	local clevy = 0
	for cx = 1, 8 do
		for cy = 1, 8 do
			if (interface.is_selected(cx, cy)) then
				clevx = cx
				clevy = cy
				cx = 8
				cy = 8
			end
		end
	end
	if (clevx > 0 and clevy > 0) and (clevx ~= x or clevy ~= y) then
		local dlev = (x * 8 + y) - (clevx * 8 + clevy)
		local dx = (x - clevx + 8) % 8
		local dy = y - clevy
		if (dlev >= -7 and dlev <= 4) then
			dx = 0
			dy = dlev
		end
		for i = 1, dx do
			send_input(":IN.4", 0x02, 1) -- Tab
		end
		for i = 1, math.abs(dy) do
			if (dy > 0) then
				send_input(":IN.5", 0x01, 1) -- +
			else
				send_input(":IN.4", 0x04, 1) -- -
			end
		end
	end
	interface.invert = invert
	emu.wait(0.5)
	send_input(":IN.7", 0x04, 1) -- Normal
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	emu.wait(8)
	sb_reset_board(":board")
	interface.invert = false
	emu.wait(1)
	send_input(":IN.1", 0x04, 1) -- New Game
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = "a3"
	interface.setlevel()

end

function setpiece(n)
	if     (n == 1) then send_input(":IN.3", 0x04, 0.5) -- K
	elseif (n == 2) then send_input(":IN.3", 0x01, 0.5) -- Q
	elseif (n == 3) then send_input(":IN.2", 0x01, 0.5) -- R
	elseif (n == 4) then send_input(":IN.2", 0x04, 0.5) -- B
	elseif (n == 5) then send_input(":IN.3", 0x02, 0.5) -- N
	elseif (n == 6) then send_input(":IN.2", 0x02, 0.5) -- P
	end
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.0", 0x01, 0.5) -- SET UP
		emu.wait(0.5)
		send_input(":IN.1", 0x01, 0.5) -- SOUND
		emu.wait(0.5)
		send_input(":IN.5", 0x02, 0.5) -- FUNCTION
		send_input(":IN.1", 0x04, 0.5) -- NEW GAME
		machine.video.throttled = throttled_state
		return (":board")
	else
		local piece = 7
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if p * piece < 0 then
						send_input(":IN.4", 0x02, 0.5) -- TAB/COLOR
					end
					setpiece(math.abs(p))
					sb_press_square(":board", 0.5, x, 9 - y)
					piece = p
				end
			end
		end
		if mode * piece < 0 then
			send_input(":IN.4", 0x02, 0.5) -- TAB/COLOR
		end
		emu.wait(0.5)
		send_input(":IN.1", 0x01, 0.5) -- SOUND
		emu.wait(0.5)
		send_input(":IN.7", 0x04, 0.5) -- NORMAL
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	if on then
		send_input(":IN.7", 0x02, 1) -- Analysis
	else
		send_input(":IN.7", 0x04, 1) -- Normal
	end
	emu.wait(0.5)
end

function interface.start_play(init)
	if (init) then
		sb_rotate_board(":board")
		interface.invert = true
	end
	send_input(":IN.4", 0x01, 1) -- Play
end

function interface.is_selected(x, y)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	local xval = output:get_indexed_value("1.", x - 1) ~= 0
	local yval = output:get_indexed_value("0.", y - 1) ~= 0
	return xval and yval
end

function interface.select_piece(x, y, event)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "string", "Level", "a3" },
	}
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		interface.level = value:lower():match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		interface.setlevel()
	end
	send_input(":IN.7", 0x04, 1) -- Normal
end

function getpiece()
	local piece = 0x00
	for i = 1, 7 do
		if (output:get_value("s" .. (i + 8) .. ".12") ~= 0) then
			piece = piece | (1 << (i - 1))
		end
	end
	return piece
end

function interface.get_promotion(x, y)
	local piece = getpiece()
	if	   (piece == 0x3e) then return 'q'
	elseif (piece == 0x3f) then return 'r'
	elseif (piece == 0x36) then return 'b'
	elseif (piece == 0x7c) then return 'n'
	end
	return nil
end

function interface.promote_special(piece)
	if     (piece == "q") then send_input(":IN.3", 0x01, 1)
	elseif (piece == "r") then send_input(":IN.2", 0x01, 1)
	elseif (piece == "b") then send_input(":IN.2", 0x04, 1)
	elseif (piece == "n") then send_input(":IN.3", 0x02, 1)
	end
end

function interface.promote(x, y, piece)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	sb_promote(":board", x, y, piece)
end

function digit_ascii(digit)
	if     digit == 0   then return " "
	elseif digit == 1   then return ":"
	elseif digit == 2   then return "f" --02
	elseif digit == 3   then return "/"
	elseif digit == 14  then return "Info"
	elseif digit == 15  then return "Level"
	elseif digit == 16  then return "Clock"
	elseif digit == 64  then return "-"
	elseif digit == 63  then return "0"
	elseif digit == 6   then return "1"
	elseif digit == 80  then return "r"
	elseif digit == 88  then return "c"
	elseif digit == 91  then return "2"
	elseif digit == 92  then return "o"
	elseif digit == 79  then return "3"
	elseif digit == 102 then return "4"
	elseif digit == 109 then return "5" --6d
	elseif digit == 115 then return "P" --73
	elseif digit == 125 then return "6"
	elseif digit == 7   then return "7" --07
	elseif digit == 127 then return "8"
	elseif digit == 111 then return "9"
	elseif digit == 55  then return "n" --37
	elseif digit == 119 then return "a" --77
	elseif digit == 124 then return "b"
	elseif digit == 57  then return "c"
	elseif digit == 94  then return "d"
	elseif digit == 121 then return "e" --79
	elseif digit == 113 then return "f"
	elseif digit == 61  then return "g"
	elseif digit == 118 then return "h"
	elseif digit == 116 then return "h"
	elseif digit == 8   then return "_"
	else                     return ""
	end
end

return interface
