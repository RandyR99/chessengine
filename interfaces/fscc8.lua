interface = {}
interface.setup_underpromotion = true -- the player's underpromotion goes in through the position setup
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

interface.level = 1
interface.cur_level = nil
interface.cur_color = 1
interface.edit = false

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	return "Fidelity Sensory 8"
end

function interface.get_author()
	return "Ron Nelson"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	repeat
		send_input(":IN.0", 0x40, 0.6) -- CL
	until output_value("7." .. interface.level-1) ~= 0
end

function interface.setup_machine()
	sb_reset_board(":board")
	send_input(":IN.0", 0x80, 1) -- RE
	emu.wait(1.0)
	interface.cur_color = 1

	interface.cur_level = 1
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		return (":board")
	else
		if mode==-1 then
			sb_press_square(":board", 0.6, 5, 8)
			emu.wait(1)
			for y=1,8 do
				for x=1,8 do
					if interface.is_selected(x, y) then
						sb_press_square(":board", 0.6, x, y)
					end
				end
			end
		end
		local key=0x00
		for n=1,6 do
			if     n==1 then key=0x20 -- K
			elseif n==2 then key=0x10 -- Q
			elseif n==3 then key=0x02 -- R
			elseif n==4 then key=0x08 -- B
			elseif n==5 then key=0x04 -- N
			elseif n==6 then key=0x01 -- P
			end
			send_input(":IN.0", key, 0.6)
			send_input(":IN.0", key, 0.6)
			send_input(":IN.0", 0x40, 0.6) -- CL
			for y=1,8 do
				for x=1,8 do
					if get_piece_id(x,y)==n then
						sb_press_square(":board", 0.6, x, y)
					end
				end
			end
			send_input(":IN.0", key, 0.6)
			send_input(":IN.0", 0x40, 0.6) -- CL
			for y=1,8 do
				for x=1,8 do
					if get_piece_id(x,y)==-n then
						sb_press_square(":board", 0.6, x, y)
					end
				end
			end
			send_input(":IN.0", key, 0.6)
		end
		interface.cur_color=mode
	end
end

function interface.start_play(init)
	for y=1,8 do
		for x=1,8 do
			if get_piece_id(x,y)==-interface.cur_color then
				sb_press_square(":board", 0.6, x, y)
				return
			end
		end
	end
end

function interface.is_selected(x, y)
	if (output_value("0.0") ~= 0 and output_value("1.0") ~= 0 and output_value("2.0") ~= 0 and output_value("3.0") ~= 0 or
	    output_value("4.0") ~= 0 and output_value("5.0") ~= 0 and output_value("6.0") ~= 0 and output_value("7.0") ~= 0) then
		-- all LEDs of a rank or file: the machine announces mate
		return false
	end
	return output_value(tostring(x - 1) .. "." .. tostring(y - 1)) ~= 0
end

function interface.edit_game(on)
	-- move the history pieces silently, then set up the final position
	interface.edit = on
	if not on then
		-- set_pos(-1) changes sides with the black king on e8: start from RE
		local stm = interface.cur_color
		send_input(":IN.0", 0x80, 1) -- RE
		emu.wait(1.0)
		local level = interface.cur_level
		interface.cur_level = 1
		if level ~= nil then
			interface.setlevel()
		end
		interface.set_pos(stm)
	end
end

function interface.select_piece(x, y, event)
	if interface.edit then
		if (event == "capture" or event == "en_passant") then
			sb_remove_piece(":board", x, y)
		else
			sb_move_piece(":board", x, y)
		end
	elseif (event == "en_passant") then
		sb_remove_piece(":board", x, y)
	elseif (event == "get_castling" or event == "put_castling") then
		sb_move_piece(":board", x, y)
	else
		sb_select_piece(":board", 1, x, y, event)
	end
	if event == "put" then
		interface.cur_color = -interface.cur_color
	end
end

function interface.get_options()
	return { { "spin", "Level", "1", "1", "8"}, }
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 8) then
			return
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
	sb_promote(":board", x, y, "q")	-- the machine only takes a queen
end

return interface
