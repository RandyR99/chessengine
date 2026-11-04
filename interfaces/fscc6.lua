interface = {}
interface.setup_underpromotion = true -- the player's underpromotion goes in through the position setup
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

interface.level = 1
interface.cur_level = nil
interface.edit = false
interface.stm = 1 -- side to move: 1 White, -1 Black

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	return "Fidelity Sensory 6"
end

function interface.get_author()
	return "Ron Nelson"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local lcd_num = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d }
	repeat
		send_input(":IN.0", 0x08, 0.6) -- LV
	until output_value("digit1") == lcd_num[interface.level]

	send_input(":IN.0", 0x40, 0.5) -- CL
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	sb_reset_board(":board")
	interface.stm = 1
	interface.edit = false
	send_input(":IN.0", 0x40, 0.5) -- CL
	emu.wait(1)
	interface.cur_level = 1
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		return (":board")
	else
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		local ram = machine.devices[':maincpu'].spaces['data']
		local fig = {0xff,0xfe,0xfd,0xfc,0xfb,0xfa,0x00,0x06,0x05,0x04,0x03,0x02,0x01}
		local adr = 0x0088
		send_input(":IN.0", 0x20, 0.5) -- PB
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, y)
				local z = fig[p + 7]
				ram:write_u8(adr + 16 * (y - 1) + x - 1, z)
			end
		end
		if mode == -1 then
			ram:write_u8(0x0003, 0x00)
		end
		interface.stm = mode
		send_input(":IN.0", 0x40, 0.5) -- CL
		machine.video.throttled = throttled_state
	end
end

function interface.edit_game(on)
	-- move the history pieces silently, then set up the final position
	interface.edit = on
	if not on then
		interface.set_pos(0)
		interface.set_pos(interface.stm)
	end
end

function interface.start_play(init)
	send_input(":IN.0", 0x01, 0.5) -- RV
end

function interface.is_selected(x, y)
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	return xval[x] == output_value("digit0") and yval[y] == output_value("digit1")
end

function interface.select_piece(x, y, event)
	if (event == "put") then
		interface.stm = -interface.stm
	end
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
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "1", "6" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 6) then
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

