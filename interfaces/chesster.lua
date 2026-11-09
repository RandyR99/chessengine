interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

interface.opt_clear_announcements = true
interface.level = "a1"
interface.cur_level = nil

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	if machine.system.name == "chesster" then
		return "Fidelity Chesster"
	elseif machine.system.name == "chesstera" then
		return "Fidelity Chesster v2"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Dan & Kathe Spracklen"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local cols_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
	local x = cols_idx[interface.level:sub(1, 1)]
	local y = interface.level:sub(2, 2)
	send_input(":IN.0", 0x10, 1)  		-- LEVEL
	emu.wait(0.5)
	sb_press_square(":board", 1, x, y)
	emu.wait(0.5)
	send_input(":IN.0", 0x01, 1) 		-- CLEAR
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	-- let the power-on greeting play at real speed (sound is muted while unthrottled)
	machine.video.throttled = true
	sb_reset_board(":board")
	emu.wait(5)
	send_input(":IN.0", 0x20, 1) 		-- OPTION -- B1 turns the character voice off
	emu.wait(1)
	sb_press_square(":board", 1, 2, 1) 	-- b1 (announced: wait for the speech before CLEAR)
	emu.wait(4)
	send_input(":IN.0", 0x01, 1) 		-- CLEAR
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = "a1"
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.0", 0x20, 1) -- OPTION
		send_input(":IN.0", 0x40, 1) -- PROBLEM
		machine.video.throttled = throttled_state
		return (":board")
	else
		local piece = 7
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if math.abs(p) ~= math.abs(piece) then
						send_input(":IN.0", 0x80 >> (math.abs(p)), 0.5)
					end
					sb_press_square(":board", 0.5, x, 9 - y)
					if p < 0 then
						sb_press_square(":board", 0.5, x, 9 - y)
					end
					piece = p
				end
			end
		end
		if mode == -1 then
			send_input(":IN.0", 0x80, 1) -- SHIFT
			send_input(":IN.0", 0x04, 1) -- YES
		end
		send_input(":IN.0", 0x01, 1) -- CLEAR
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.0", 0x20, 1) -- OPTION
	sb_press_square(":board", 1, 3, 1)
	send_input(":IN.0", 0x01, 1) -- CLEAR
	emu.wait(0.5)
	machine.video.throttled = throttled_state
end

function interface.start_play(init)
	send_input(":IN.0", 0x02, 1) 		-- MOVE
end

function interface.clear_announcements()
	if (output_value("9.1") ~= 0) then
		send_input(":IN.0", 0x01, 0.5) 	-- CLEAR
	end
end

function interface.is_selected(x, y)
	if (interface.opt_clear_announcements and x == 1 and y == 1) then
		interface.clear_announcements()
	end

	return (output_value("0." .. tostring(y - 1)) ~= 0 and output_value("1." .. tostring(x - 1)) ~= 0)
end

function interface.select_piece(x, y, event)
	if (event == "get_castling") then
		emu.wait(1)
	end
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "string", "Level", "a1"},
		{ "check", "Clear announcements", "1" },
	}
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		interface.level = value:lower():match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		interface.setlevel()
	end
	if (name == "clear announcements") then
		interface.opt_clear_announcements = tonumber(value) == 1
	end
end

function interface.test_promotion(x, y)
	local function piece_led(port, code, x, y)
		for n=1,8 do
			send_input(port, code, 0.5)
			for i=1,4 do
				if (output_value("0." .. tostring(y - 1)) ~= 0 and output_value("1." .. tostring(x - 1)) ~= 0) then
					return true
				end
				emu.wait(0.15)
			end
		end
		return false
	end

	if (interface.opt_clear_announcements) then
		interface.clear_announcements()
	end

	local p
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	emu.wait(1)
	send_input(":IN.0", 0x40, 1) -- VERIFY

	if	 piece_led(":IN.0", 0x20, x, y) then p = "Q"
	elseif piece_led(":IN.0", 0x04, x, y) then p = "N"
	elseif piece_led(":IN.0", 0x08, x, y) then p = "B"
	elseif piece_led(":IN.0", 0x10, x, y) then p = "R"
	else p = "Q"
	end

	emu.wait(1)
	send_input(":IN.0", 0x01, 1) -- CLEAR
	machine.video.throttled = throttled_state
	return p
end

function interface.get_promotion(x, y)
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	emu.wait(1.0)
	if	 (piece == "q") then	send_input(":IN.0", 0x20, 1)
	elseif (piece == "r") then	send_input(":IN.0", 0x10, 1)
	elseif (piece == "b") then	send_input(":IN.0", 0x08, 1)
	elseif (piece == "n") then	send_input(":IN.0", 0x04, 1)
	end
end

return interface

