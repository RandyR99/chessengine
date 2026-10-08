interface = {}

interface.level = 1
interface.cur_level = nil
interface.cur_color = 1

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	repeat
		send_input(":IN.0", 0x40, 0.6) -- CL
		
		-- Use the machine object to resolve the output proxy directly
		local led_name = "7." .. tostring(interface.level - 1)
		local led_state = machine.devices[":"]:output(led_name)
	until led_state and led_state:get() ~= 0
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
	-- Check for mate announcement by pulling the output proxies for rows 0.0 to 7.0
	local mate_0 = machine.devices[":"]:output("0.0")
	local mate_1 = machine.devices[":"]:output("1.0")
	local mate_2 = machine.devices[":"]:output("2.0")
	local mate_3 = machine.devices[":"]:output("3.0")
	local mate_4 = machine.devices[":"]:output("4.0")
	local mate_5 = machine.devices[":"]:output("5.0")
	local mate_6 = machine.devices[":"]:output("6.0")
	local mate_7 = machine.devices[":"]:output("7.0")

	if ((mate_0 and mate_0:get() ~= 0 and mate_1 and mate_1:get() ~= 0 and mate_2 and mate_2:get() ~= 0 and mate_3 and mate_3:get() ~= 0) or
	    (mate_4 and mate_4:get() ~= 0 and mate_5 and mate_5:get() ~= 0 and mate_6 and mate_6:get() ~= 0 and mate_7 and mate_7:get() ~= 0)) then
		-- TODO: machine turns on all LEDs for mate announcement
		return false
	end

	-- Check the specific square requested
	local led_name = tostring(x - 1) .. "." .. tostring(y - 1)
	local led_state = machine.devices[":"]:output(led_name)
	
	return led_state and led_state:get() ~= 0
end

function interface.select_piece(x, y, event)
	if (event == "en_passant") then
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
	sb_promote(":board", x, y, "q")	-- TODO
end

return interface
