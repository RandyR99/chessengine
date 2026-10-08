interface = {}

interface.level = 0
interface.cur_level = nil

function interface.get_module()
	return "Destiny Prodigy"
end

function interface.get_author()
	return "John Aker"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	if (output:get_value("digit0") ~= 0x38) then
		send_input(":IN.0", 0x040, 1) -- LEVEL
	end
	interface.send_pos(interface.level)
	send_input(":IN.0", 0x200, 1) -- ENTER
end

function interface.setup_machine()
	sb_reset_board(":board")
	emu.wait(1)
	interface.cur_level = ""
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.0", 0x080, 0.5) -- CHANGE BOARD
		send_input(":IN.0", 0x020, 0.5) -- CE
		machine.video.throttled = throttled_state
		return (":board")
	else
		local piece = 7
		local x0, y0
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p == mode then
					x0 = x
					y0 = 9 - y
				elseif p ~= 0 then
					if p ~= piece then
						if p > 0 then
							send_input(":IN.1", 0x200, 0.5) -- WHITE
						else
							send_input(":IN.1", 0x001, 0.5) -- BLACK
						end
						interface.send_pos(7 - math.abs(p))
					end
					sb_press_square(":board", 0.5, x, 9 - y)
					piece = p
				end
			end
		end
		if mode == 1 then
			send_input(":IN.1", 0x200, 0.5) -- WHITE
		else
			send_input(":IN.1", 0x001, 0.5) -- BLACK
		end
		interface.send_pos(7 - math.abs(mode))
		sb_press_square(":board", 0.5, x0, y0)
		send_input(":IN.0", 0x200, 0.5) -- ENTER
	end
	machine.video.throttled = throttled_state
end

function interface.start_play(init)
	send_input(":IN.0", 0x001, 1) -- GO
end

function interface.stop_play()
	send_input(":IN.1", 0x010, 1) -- HALT
end

function interface.is_selected(x, y)
	local xval = output:get_value("4." .. tostring(x - 1)) ~= 0
	local yval = output:get_value("5." .. tostring(y - 1)) ~= 0
	return xval and yval
end

function interface.send_pos(p)
	if     (p == 1)	then send_input(":IN.0", 0x002, 0.5)
	elseif (p == 2)	then send_input(":IN.1", 0x002, 0.5)
	elseif (p == 3)	then send_input(":IN.1", 0x100, 0.5)
	elseif (p == 4)	then send_input(":IN.0", 0x004, 0.5)
	elseif (p == 5)	then send_input(":IN.1", 0x004, 0.5)
	elseif (p == 6)	then send_input(":IN.1", 0x080, 0.5)
	elseif (p == 7)	then send_input(":IN.0", 0x008, 0.5)
	elseif (p == 8)	then send_input(":IN.1", 0x008, 0.5)
	end
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "spin", "Level", "0", "0", "8" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 0 or level > 8) then
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
	sb_promote(":board", x, y, "q") -- TODO
end

return interface
