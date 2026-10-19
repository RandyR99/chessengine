interface = {}

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.level = 1
interface.cur_level = nil

function interface.get_module()
	return "SciSys Travel Sensor Chess"
end

function interface.get_author()
	return "David Levy & Mark Taylor"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	-- while LEVEL is held, a rank LED shows the level (rank 1 = level 1); the first press
	-- only shows it, each further press steps 1-2-3-4-1
	local level_key = machine.ioport.ports[":IN.1"]:field(0x80)
	for i = 1, 8 do
		level_key:set_value(1)
		emu.wait(0.3)
		local shown = 0
		for y = 1, 4 do
			if output_value("2." .. (8 - y)) ~= 0 then
				shown = y
			end
		end
		level_key:clear_value()
		emu.wait(0.4)
		if shown == interface.level then
			break
		end
	end
end

function interface.setup_machine()
	sb_reset_board(":board")
	emu.wait(1)
	interface.cur_level = 1
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.1", 0x20, 0.6) -- Set Up
		return (":board")
	else
		-- board at 16 * (x - 1) + y - 1: P1 N2 B3 R4 Q5 K6, black + 8
		local ram = machine.devices[":maincpu"].spaces["data"]
		local fig = { 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x00, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01 }
		for x = 1, 8 do
			for y = 1, 8 do
				ram:write_u8(16 * (x - 1) + y - 1, fig[get_piece_id(x, y) + 7])
			end
		end
		if mode == -1 then
			ram:write_u8(0xc5, 0x02)
		end
		send_input(":IN.1", 0x20, 0.6) -- Set Up
	end
end

function interface.edit_game()
	send_input(":IN.1", 0x20, 0.6) -- Set Up
end

function interface.start_play(init)
	send_input(":IN.1", 0x10, 0.6) -- Compute
end

function interface.stop_play()
end

function interface.is_selected(x, y)
	local xval = output_value("1." .. (8 - x)) ~= 0
	local yval = output_value("2." .. (8 - y)) ~= 0
	return xval and yval
end

function interface.select_piece(x, y, event)
	if (event == "en_passant") then
		sb_remove_piece(":board", x, y)
	elseif (event == "get_castling" or event == "put_castling") then
		sb_move_piece(":board", x, y)
	else
		sb_select_piece(":board", 1, x, y, event)
	end
	-- the slow MCU (~400 kHz) misses board events that come too close together
	emu.wait(1)
end

function interface.get_options()
	return { { "spin", "Level", "1", "1", "4" }, }
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level == nil or level < 1 or level > 4) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	return 'q' -- the engine always promotes to a queen
end

function interface.promote(x, y, piece)
	promotion_error(piece)
	sb_promote(":board", x, y, "q")
end

return interface
