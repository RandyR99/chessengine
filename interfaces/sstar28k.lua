interface = {}

interface.invert = false
interface.level = "a1"
interface.cur_level = nil

function interface.get_module()
	return "SciSys Superstar 28K"
end

function interface.get_author()
	return "Julio Kaplan"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local cols_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
	local x = cols_idx[interface.level:sub(1, 1)]
	local y = interface.level:sub(2, 2)
	send_input(":IN.0", 0x08, 0.5)	-- LEVEL
	sb_press_square(":board", 0.5, x, y)
end

function setpiece(n)
	if     (n == 1) then send_input(":IN.1", 0x01, 0.75) -- K
	elseif (n == 2) then send_input(":IN.0", 0x01, 0.75) -- Q
	elseif (n == 3) then send_input(":IN.1", 0x02, 0.75) -- R
	elseif (n == 4) then send_input(":IN.0", 0x02, 0.75) -- B
	elseif (n == 5) then send_input(":IN.1", 0x04, 0.75) -- N
	elseif (n == 6) then send_input(":IN.0", 0x04, 0.75) -- P
	end
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.1", 0x08, 0.75) -- Set Up
		send_input(":IN.0", 0x10, 0.75) -- Sound
		send_input(":IN.0", 0x20, 0.75) -- New Game
		machine.video.throttled = throttled_state
		return (":board")
	else
		local piece = 7
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if p * piece < 0 then
						send_input(":IN.1", 0x20, 0.75) -- Color
					end
					if math.abs(p) ~= math.abs(piece) then
						setpiece(math.abs(p))
					end
					sb_press_square(":board", 0.75, x, 9 - y)
					piece = p
				end
			end
		end
		if mode * piece < 0 then
			send_input(":IN.1", 0x20, 0.75) -- Color
		end
		send_input(":IN.1", 0x08, 0.75) -- Setup
		send_input(":IN.0", 0x10, 0.75) -- Sound
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game()
	send_input(":IN.1", 0x10, 0.75) -- MULTI MOVE
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	interface.invert = false
	emu.wait(9)
	send_input(":IN.0", 0x20, 1)	-- NEW GAME
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = "a1"
	interface.setlevel()
end

function interface.start_play(init)
	if (init) then
		sb_rotate_board(":board")
		interface.invert = true
	end
	send_input(":IN.1", 0x80, 1)	-- MOVE
end

function interface.is_selected(x, y)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	local xval = output:get_value(tostring(x - 1) .. ".0") ~= 0
	local yval = output:get_value(tostring(y - 1) .. ".1") ~= 0
	return xval and yval
end

function interface.select_piece(x, y, event)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	sb_select_piece(":board", 1, x, y, event)
	if (event == "put" or event == "put_castling") then
		emu.wait(1)
	end
end

function interface.get_options()
	return {
		{ "string", "Level", "a1" },
	}
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:match("^%s*(.-)%s*$"):gsub("%s%s+"," "):lower() -- trim
		if (level:match("[abh][1-8]")) then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.get_promotion(x, y)
	for i = 0, 5 do
		if     (output:get_value("9.1") ~= 0) then return 'q'
		elseif (output:get_value("9.2") ~= 0) then return 'r'
		elseif (output:get_value("8.0") ~= 0) then return 'b'
		elseif (output:get_value("8.1") ~= 0) then return 'n'
		end
		emu.wait(0.2)
	end
	return nil
end

function interface.promote(x, y, piece)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	sb_promote(":board", x, y, piece)
	if     (piece == "q" or piece == "Q") then send_input(":IN.0", 0x01, 1)
	elseif (piece == "r" or piece == "R") then send_input(":IN.1", 0x02, 1)
	elseif (piece == "b" or piece == "B") then send_input(":IN.0", 0x02, 1)
	elseif (piece == "n" or piece == "N") then send_input(":IN.1", 0x04, 1)
	end
end

return interface
