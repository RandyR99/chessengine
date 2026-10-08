interface = {}

interface.level = 1
interface.cur_level = nil

function interface.get_module()
	return "CXG Sensor Computachess v2"
end

function interface.get_author()
	return "David Levy & Mark Taylor"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	repeat
		send_input(":IN.0", 0x80, 0.6) -- Level
		local cur_level = 0
		for y = 0, 7 do
			if output:get_indexed_value(7 - y .. ".", 1) ~= 0 then
				cur_level = cur_level + 1
			end
		end
	until (cur_level == interface.level)
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	sb_reset_board(":board")
	emu.wait(1)
	interface.cur_level = 1
	interface.setlevel()
end

function interface.start_play(init)
	send_input(":IN.0", 0x40, 1) -- Reverse Play
end

function interface.stop_play()
end

function interface.is_selected(x, y)
	local xval = output:get_value(tostring(8 - x) .. ".0") ~= 0
	local yval = output:get_value(tostring(8 - y) .. ".1") ~= 0
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
	return 'q'	-- engine always promotes to Queen
end

function interface.promote(x, y, piece)
	promotion_error(piece)
	sb_promote(":board", x, y, "q")	-- TODO
end

return interface
