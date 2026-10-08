interface = {}

interface.invert = false
interface.level = "a4"
interface.cur_level = nil

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local level = interface.level
	local cols_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
	send_input(":IN.1", 0x40, 0.5) -- LEVEL
	sb_press_square(":board", 0.5, cols_idx[level:sub(1,1)], level:sub(2,2))
	send_input(":IN.1", 0x40, 0.5) -- LEVEL
end

function interface.setup_machine()
	sb_reset_board(":board")
	interface.invert = false
    send_input(":IN.1", 0x01, 0.5) -- RESET
	emu.wait(6.5)

	interface.cur_level = "a4"
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.1", 0x02, 0.9) -- POSITION
		send_input(":IN.1", 0x01, 0.9) -- RESET
		return (":board")
	else
		local piece=7
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if p*piece<0 then
						send_input(":IN.1", 0x04, 0.9) -- COLOR
					end
					if math.abs(p)~=math.abs(piece) then
						send_input(":IN.0", 0x01<<(6-math.abs(p)), 0.9)
					end
					sb_press_square(":board", 0.9, x, 9-y)
					piece=p
				end
			end
		end
		if mode*piece<0 then
			send_input(":IN.1", 0x04, 0.9) -- COLOR
		end
		send_input(":IN.1", 0x02, 0.9) -- POSITION
	end
end

function interface.edit_game(on)
	send_input(":IN.1", 0x80, 0.5) -- MONITOR
	emu.wait(0.5)
end

function interface.start_play(init)
	if (init) then
		sb_rotate_board(":board")
		interface.invert = true
	end
	send_input(":IN.0", 0x80, 0.5) -- MOVE
end

function interface.is_selected(x, y)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	local xval = output:get_value("1." .. tostring(x - 1)) ~= 0
	local yval = output:get_value("0." .. tostring(y - 1)) ~= 0
	return xval and yval
end

function interface.select_piece(x, y, event)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	sb_select_piece(":board", 0.5, x, y, event)
end

function interface.get_options()
	return { { "string", "Level", "a4"}, }
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:match("^%s*(.-)%s*$"):gsub("%s%s+"," "):lower() -- trim
		if (level:match("^[a-e][1-8]$")) then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.get_promotion(x, y)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	sb_press_square(":board", 0.5, x, y)
	if     (output:get_value("s0.28") ~= 0) then return 'q'
	elseif (output:get_value("s0.26") ~= 0) then return 'r'
	elseif (output:get_value("s0.24") ~= 0) then return 'b'
	elseif (output:get_value("s0.15") ~= 0) then return 'n'
	end
	return p
end

function interface.promote(x, y, piece)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	sb_promote(":board", x, y, piece)
	if (not interface.is_selected(x, y)) then
		if     (piece == "q") then send_input(":IN.0", 0x10, 1)
		elseif (piece == "r") then send_input(":IN.0", 0x08, 1)
		elseif (piece == "b") then send_input(":IN.0", 0x04, 1)
		elseif (piece == "n") then send_input(":IN.0", 0x02, 1)
		end
	end
end

return interface
