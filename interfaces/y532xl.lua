interface = {}

interface.level = "TI 1"
interface.cur_level = nil
local Ticker = 1

function interface.get_module()
	return "Yeno 532 XL"
end

function interface.get_author()
	return "Ulf Rathsman"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local tmp = interface.level:sub(1,2)
	local num = 0x31
	if	   (tmp == "TI") then num = 0x31
	elseif (tmp == "DE") then num = 0x5e
	elseif (tmp == "MA") then num = 0x37
	end
	local n = tonumber(interface.level:sub(3,4))
	repeat
		send_input(":IN.1", 0x02, 0.5) -- Level
	until (output:get_value("digit3") == num)
	if (n == 10) then
		send_input(":IN.1", 0x80, 0.5) -- 10
	elseif (n == 9) then
		send_input(":IN.1", 0x40, 0.5) -- 0
	else
		send_input(":IN.2", 1 << (n - 1), 0.5)
	end
	send_input(":IN.1", 0x01, 0.5) -- Play
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	emu.wait(1)
	if (output:get_value("digit7") ~= 0x3f) then
		send_input(":IN.1", 0x04, 1) -- New Game
		emu.wait(1)
	end
	machine.video.throttled = throttled_state
	interface.cur_level = ""
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.1", 0x08, 0.5) -- Set Up
		send_input(":IN.1", 0x04, 0.5) -- Cl.Board
		sb_clear_board(":board")
		machine.video.throttled = throttled_state
		return (":board")
	else
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					sb_press_square(":board", 1, x, 9 - y)
					send_input(":IN.2", 0x40 >> math.abs(p), 0.5)
					if p < 0 then
						send_input(":IN.2", 0x40 >> math.abs(p), 0.5)
					end
				end
			end
		end
		if mode == 1 then
			send_input(":IN.2", 0x80, 0.5) -- White
		else
			send_input(":IN.2", 0x40, 0.5) -- Black
		end
		send_input(":IN.1", 0x01, 0.5) -- Play
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	if on then
		send_input(":IN.1", 0x10, 0.5) -- MultiMove
		emu.wait(0.5)
	end
end

function interface.start_play(init)
	send_input(":IN.1", 0x01, 1) -- Play
end

function interface.is_selected(x, y)
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	local d7 = output:get_value("digit7") & 0x7f
	local d6 = output:get_value("digit6") & 0x7f
	local d5 = output:get_value("digit5") & 0x7f
	local d4 = output:get_value("digit4") & 0x7f
	if (d7 == 0x73) then -- promotion
		return output:get_value((x - 1) .. "." .. (y - 1)) ~= 0
	else
		return (xval[x] == d7 and yval[y] == d6) or (xval[x] == d5 and yval[y] == d4)
	end
end

function interface.select_piece(x, y, event)
	if (event == "en_passant") then
		sb_remove_piece(":board", x, y)
	else
		sb_select_piece(":board", 1, x, y, event)
	end
end

function interface.get_options()
	return {
		{ "string", "Level", "TI 1" },
	}
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = string.upper(value:match("^%s*(.-)%s*$"):gsub("%s%s+"," ")) -- trim
		local tmp = level:sub(1,2)
		if (tmp ~= "TI" and tmp ~= "DE" and tmp ~= "MA") then
			level = "TI" .. level
		end
		local n = tonumber(level:sub(3,level:len()))
		if (n == nil or n < 1 or n > 10) then
			return
		end
		if (n < 10) then
			level = level:sub(1,2) .. " " .. tostring(n)
		else
			level = level:sub(1,2) .. "10"
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	if (output:get_value("digit7") == 0x73) then
		local piece = output:get_value("digit4")
		if     (piece == 0x67) then return 'q'
		elseif (piece == 0x44) then return 'r'
		elseif (piece == 0x7c) then return 'b'
		elseif (piece == 0x54) then return 'n'
		end
	end
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	emu.wait(1)
	if     (piece == "q") then send_input(":IN.2", 0x10, 1)
	elseif (piece == "r") then send_input(":IN.2", 0x08, 1)
	elseif (piece == "b") then send_input(":IN.2", 0x04, 1)
	elseif (piece == "n") then send_input(":IN.2", 0x02, 1)
	end
end

function interface.show_info(on)
	if on and Ticker == 1 then
		local pv
		local score
		local depth
		if output:get_value("digit7") ~= 0x73 then
			send_input(":IN.0", 0x80, 0.2) -- Show Move
			emu.wait(0.2)
			local d3 = output:get_value("digit0")
			local d2 = output:get_value("digit1")
			local d1 = output:get_value("digit2")
			local d0 = output:get_value("digit3")
			local d7 = output:get_value("digit4")
			local d6 = output:get_value("digit5")
			local d5 = output:get_value("digit6")
			local d4 = output:get_value("digit7")
			Ticker = 0
			pv = digit_ascii(d4) .. digit_ascii(d5) .. digit_ascii(d6) .. digit_ascii(d7)
			score = digit_ascii(d0) .. digit_ascii(d1) .. digit_ascii(d2) .. digit_ascii(d3)
			send_input(":IN.2", 0x04, 0.2) -- 3
			emu.wait(0.2)
			d3 = output:get_value("digit0")
			d2 = output:get_value("digit1")
			d1 = output:get_value("digit2")
			d0 = output:get_value("digit3")
			if output:get_value("digit7") ~= 0x73 then
				send_input(":IN.0", 0x80, 0.2) -- Show Move
				depth = digit_ascii(d2) .. digit_ascii(d3)
			end
			return "info score cp " .. score .. " depth " .. depth .. " pv " .. pv
		end
	else
		Ticker = 1
	end
end

function digit_ascii(digit)
	if     (digit == nil) then digit = -1
	end
	local zahl = "unknown" .. tostring(digit) .. " "
	if     (digit == 0)   then zahl = " "
	elseif (digit == 64)  then zahl = "-"
	elseif (digit == 63)  then zahl = "0"
	elseif (digit == 191) then zahl = "0"
	elseif (digit == 6)   then zahl = "1"
	elseif (digit == 134) then zahl = "1"
	elseif (digit == 91)  then zahl = "2"
	elseif (digit == 219) then zahl = "2"
	elseif (digit == 79)  then zahl = "3"
	elseif (digit == 207) then zahl = "3"
	elseif (digit == 102) then zahl = "4"
	elseif (digit == 230) then zahl = "4"
	elseif (digit == 109) then zahl = "5"
	elseif (digit == 237) then zahl = "5"
	elseif (digit == 125) then zahl = "6"
	elseif (digit == 253) then zahl = "6"
	elseif (digit == 7)   then zahl = "7"
	elseif (digit == 135) then zahl = "7"
	elseif (digit == 127) then zahl = "8"
	elseif (digit == 255) then zahl = "8"
	elseif (digit == 111) then zahl = "9"
	elseif (digit == 239) then zahl = "9"
	elseif (digit == 55)  then zahl = "n"
	elseif (digit == 119) then zahl = "a"
	elseif (digit == 124) then zahl = "b"
	elseif (digit == 57)  then zahl = "c"
	elseif (digit == 94)  then zahl = "d"
	elseif (digit == 121) then zahl = "e"
	elseif (digit == 113) then zahl = "f"
	elseif (digit == 61)  then zahl = "g"
	elseif (digit == 118) then zahl = "h"
	elseif (digit == 8)   then zahl = "_"
	elseif (digit == 110) then zahl = "y"
	end
	return (zahl)
end

return interface
