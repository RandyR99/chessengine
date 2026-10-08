interface = {}

local module = machine.images[':cartslot'].filename
interface.level = 1
interface.cur_level = nil

function interface.get_module()
	return "SciSys Sensor Chess"
end

function interface.get_author()
	return "Julio Kaplan"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local level = interface.level
	while output:get_indexed_value("7.", level - 1) == 0 do
		send_input(":IN.0", 0x10, 1.0) -- Level
	end
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	if module == "csss" or module == "strong" then
		emu.wait(9)
	end
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = 1
	interface.setlevel()
end

--[[
function interface.set_pos(mode)
	if mode == 0 then
		return (":board")
	else
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		local ram = emu.item(machine.devices[':maincpu'].items['0/0000-ffff'])
		local fig = {0xc6, 0x84, 0x81, 0x82, 0x83, 0x85, 0x00, 0x05, 0x03, 0x02, 0x01, 0x04, 0x46}
		for x = 1, 8 do
			for y = 1, 8 do
				local p = get_piece_id(x, y)
				local z = fig[p + 7]
				ram:write(16 * (x - 1) + y - 1, z)
			end
		end
		if mode == -1 then
			send_input(":IN.0", 0x20, 1) -- White
		end
		machine.video.throttled = throttled_state
	end
end
--]]

function interface.edit_game(on)
	if on then
		send_input(":IN.2", 0x04, 1) -- Player-Player
	else
		send_input(":IN.0", 0x04, 1) -- Player-Computer
	end
end

function interface.start_play(init)
	send_input(":IN.2", 0x10, 1)    -- Move
end

function interface.stop_play()
	send_input(":IN.2", 0x08, 1)    -- Interrupt
end

function interface.is_selected(x, y)
	if (output:get_value((x - 1) .. "." .. (y - 1)) ~= 0) then
		if (math.abs(get_piece_id(x, y)) == 1) then
			emu.wait(1.5)
			return output:get_value((x - 1) .. "." .. (y - 1)) ~= 0
		end
		return true
	end
	return false
end

function interface.select_piece(x, y, event)
    if (event == "en_passant") then
        sb_remove_piece(":board", x, y)
        if output:get_value((x - 1) .. "." .. (y - 1)) ~= 0 then
            sb_press_square(":board", 0.5, x, y)
        end
	elseif (event == "get_castling" or event == "put_castling") then
		sb_move_piece(":board", x, y)
	else
		sb_select_piece(":board", 0.5, x, y, event)
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
	if     (output:get_value("8.4") ~= 0) then return 'q'
	elseif (output:get_value("8.3") ~= 0) then return 'r'
	elseif (output:get_value("8.1") ~= 0) then return 'b'
	elseif (output:get_value("8.2") ~= 0) then return 'n'
	end
	return nil
end

function interface.promote(x, y, piece)
	if piece == piece:lower() then
		promotion_error(piece)
		sb_promote(":board", x, y, "q")	-- TODO
	else
		interface.select_piece(x, y, "")
		sb_promote(":board", x, y, piece)
 	end
end

return interface
