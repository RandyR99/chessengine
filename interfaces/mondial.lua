interface = {}

interface.invert = false
interface.level = 2
interface.cur_level = nil
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

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
	if (output_value("0." .. 2-tmp) == 0) then
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
	local xval = output_value((x - 1) .. ".1") ~= 0
	local yval = output_value((y - 1) .. ".2") ~= 0
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
	-- piece LEDs above the keys: 1.0 knight .. 4.0 queen
	if	   (output_value("4.0") ~= 0) then return 'q'
	elseif (output_value("3.0") ~= 0) then return 'r'
	elseif (output_value("2.0") ~= 0) then return 'b'
	elseif (output_value("1.0") ~= 0) then return 'n'
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

