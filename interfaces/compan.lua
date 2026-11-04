interface = {}
interface.setup_underpromotion = true -- the player's underpromotion goes in through the position setup
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.level = 1
interface.cur_level = nil

function interface.get_module()
	return "SciSys Chess Companion"
end

function interface.get_author()
	return "Craig Barnes"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local level = interface.level
	while output_value(tostring(level-1) .. ".1") == 0 do
		send_input(":IN.1", 0x80, 0.6) -- Change Level
	end
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	emu.wait(2)
	machine.video.throttled = throttled_state
	interface.cur_level = 1
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		return (":board")
	else
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		local ram = machine.devices[':maincpu'].spaces['program'] -- board at 0x00, 16*(x-1)+y-1
		local fig = {0xc6,0x84,0x81,0x82,0x83,0x85,0x00,0x05,0x03,0x02,0x01,0x04,0x46}
		for x = 1, 8 do
			for y = 1, 8 do
				local p = get_piece_id(x, y)
				local z = fig[p + 7]
				ram:write_u8(16 * (x - 1) + y - 1, z)
			end
		end
		if mode == -1 then
			send_input(":IN.0", 0x80, 0.6) -- Color
		end
		machine.video.throttled = throttled_state
	end
end

function interface.edit_game()
	send_input(":IN.1", 0x40, 0.6) -- Multi Move
	emu.wait(0.5)
end

function interface.start_play(init)
	send_input(":IN.1", 0x08, 1)	-- Play
end

function interface.is_selected(x, y)
	local xval = output_value(tostring(x - 1) .. ".0") ~= 0
	local yval = output_value(tostring(y - 1) .. ".1") ~= 0
	return xval and yval
end

function interface.select_piece(x, y, event)
	if (event == "get_castling" or event == "put_castling") then
		sb_move_piece(":board", x, y)
	else
		sb_select_piece(":board", 1, x, y, event)
	end
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "1", "8" },
	}
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
	if     (output_value("1.2") ~= 0) then return 'q'
	elseif (output_value("3.2") ~= 0) then return 'r'
	elseif (output_value("5.2") ~= 0) then return 'b'
	elseif (output_value("7.2") ~= 0) then return 'n'
	end
	return nil
end

function interface.promote(x, y, piece)
	if piece == piece:lower() then
		promotion_error(piece)
		sb_promote(":board", x, y, "q")	-- the machine only takes a queen
	else
		sb_promote(":board", x, y, piece)
 	end
	sb_press_square(":board", 0.6, x, y)
end

return interface
