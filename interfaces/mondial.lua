interface = {}

interface.invert = false
interface.level = 2
interface.cur_level = nil

function interface.get_module()
	return "Mephisto Mondial"
end

function interface.get_author()
	return "Frans Morsch"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local tmp = 0
	if (interface.level > 8) then
		tmp = 1
	end
	send_input(":KEY.1", 0x20, 1) -- LEV
	emu.wait(1)
	
	-- MODERNIZED: Updated raw output lookup safely through the root proxy
	local check_node = machine.devices[":"]:output("0." .. tostring(2 - tmp))
	local check_val = check_node and check_node:get() or 0
	if (check_val == 0) then
		send_input(":KEY.1", 0x20, 1) -- LEV
		emu.wait(0.5)
	end
	send_input(":KEY.0", 0x01 << ((interface.level-1) % 8), 1)
	emu.wait(1)
	send_input(":KEY.1", 0x40, 1) -- ENT
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	interface.invert = false
	send_input(":KEY.1", 0x80, 1) -- RES
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = 2
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":KEY.1", 0x02, 1) -- POS
		send_input(":KEY.1", 0x10, 1) -- CL
		machine.video.throttled = throttled_state
		return (":board")
	else
		local piece = 7
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if p * piece < 0 then
						if p < 0 then
							send_input(":KEY.0", 0x40, 1) -- Black
						else
							send_input(":KEY.0", 0x80, 1) -- White
						end
					end
					if math.abs(p) ~= math.abs(piece) then
						send_input(":KEY.0", 0x01 << (6 - math.abs(p)), 1)
					end
					sb_press_square(":board", 1, x, 9 - y)
					piece = p
				end
			end
		end
		if mode == 1 then
			send_input(":KEY.0", 0x80, 1) -- White
		else
			send_input(":KEY.0", 0x40, 1) -- Black
		end
		send_input(":KEY.1", 0x40, 1) -- ENT
		send_input(":KEY.1", 0x01, 1) -- PLAY
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	if on then
		send_input(":KEY.1", 0x04, 0.5) -- MEM
	else
		send_input(":KEY.1", 0x01, 0.5) -- PLAY
	end
	emu.wait(0.5)
end

function interface.start_play(init)
	send_input(":KEY.1", 0x01, 1) -- PLAY
end

function interface.is_selected(x, y)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	
	-- MODERNIZED: Converted old get_indexed_value method to safe string proxy lookups
	local root = machine.devices[":"]
	local x_node = root:output(tostring(x - 1) .. ".1")
	local y_node = root:output(tostring(y - 1) .. ".2")
	
	local xval = x_node and x_node:get() ~= 0 or false
	local yval = y_node and y_node:get() ~= 0 or false
	
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
		{ "spin", "Level", "2", "1", "16" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 16) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion_led()
	-- MODERNIZED: Updated raw promotion LED array nodes securely using the root container proxy
	local root = machine.devices[":"]
	local l104 = root:output("4.0")
	local l103 = root:output("3.0")
	local l102 = root:output("2.0")
	local l101 = root:output("1.0")

	if     l104 and l104:get() ~= 0 then return 'q'
	elseif l103 and l103:get() ~= 0 then return 'r'
	elseif l102 and l102:get() ~= 0 then return 'b'
	elseif l101 and l101:get() ~= 0 then return 'n'
	end
	return nil
end

function interface.get_promotion(x, y)
	for i = 1, 5 do
		local p = interface.get_promotion_led()
		if (p ~= nil) then
			return p
		end
		emu.wait(0.25)
	end
	return nil
end

function interface.promote(x, y, piece)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	sb_promote(":board", x, y, piece)
	if	   (piece == "q") then send_input(":KEY.0", 0x10, 1)
	elseif (piece == "r") then send_input(":KEY.0", 0x08, 1)
	elseif (piece == "b") then send_input(":KEY.0", 0x04, 1)
	elseif (piece == "n") then send_input(":KEY.0", 0x02, 1)
	elseif (piece == "Q" or piece == "R" or piece == "B" or piece == "N") then
		sb_press_square(":board", 1, x, y)
	end
end

return interface

