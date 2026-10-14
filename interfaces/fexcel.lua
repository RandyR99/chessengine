local interface = {}

interface.opt_clear_announcements = true
interface.level = 6
interface.cur_level = nil

function interface.get_module()
	if machine.system.name == "fexcel" then
		return "Fidelity Excellence"
	elseif machine.system.name == "fexcela" then
		return "Fidelity Excellence v2"
	elseif machine.system.name == "fexcelv" then
		return "Fidelity Excellence Voice"
	elseif machine.system.name == "fexceld" then
		return "Fidelity Excellence Display"
	elseif machine.system.name == "fexcel12" then
		return "Fidelity Excellence EP12"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Dan & Kathe Spracklen"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	
	local root = machine.devices[":"]
	if not root then return end
	
	local led_code = { 1, 2, 4, 8, 16, 32, 64, 128, 192, 96, 48, 24 }
	local cur_leds = 0
	local cur_level = 0
	local dif_level
	send_input(":IN.0", 0x10, 0.5) -- LEVEL
	
	for y = 0, 7 do
		-- Modern non-deprecated node-object query layout
		local node = root:output("0." .. tostring(y))
		local node_val = node and node:get() or 0
		if node_val ~= 0 then
			cur_leds = cur_leds + (1 << y)
		end
	end
	
	repeat
		cur_level = cur_level + 1
	until cur_leds == led_code[cur_level]
	dif_level = interface.level - cur_level
	if (dif_level < 0) then
		dif_level = dif_level + 12
	end
	for y = 1, dif_level do
		send_input(":IN.0", 0x10, 0.5) -- LEVEL
	end
	send_input(":IN.0", 0x01, 0.5) -- CLEAR
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	sb_reset_board(":board")
	emu.wait(1)
	interface.cur_level = 6
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.0", 0x20, 0.5) -- OPTIONS
		if machine.system.name == "fexcelv" then
			sb_press_square(":board", 0.5, 2, 1) -- Sound off
		end
		sb_press_square(":board", 0.5, 7, 1) -- Clear board
		send_input(":IN.0", 0x01, 0.5) -- CLEAR
		emu.wait(0.5)
		send_input(":IN.0", 0x01, 0.5) -- CLEAR
		send_input(":IN.0", 0x20, 0.5) -- OPTIONS
		send_input(":IN.0", 0x40, 0.5) -- VERIFY
		machine.video.throttled = throttled_state
		return (":board")
	else
		local piece = 7
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if math.abs(p) ~= math.abs(piece) then
						send_input(":IN.0", 0x80 >> (math.abs(p)), 0.5)
					end
					sb_press_square(":board", 0.5, x, 9 - y)
					if p < 0 then
						sb_press_square(":board", 0.5, x, 9 - y)
					end
					piece = p
				end
			end
		end
		send_input(":IN.0", 0x01, 0.5) -- CLEAR
		if mode == -1 then
			send_input(":IN.0", 0x20, 0.5) -- OPTIONS
			sb_press_square(":board", 0.5, 5, 1) -- Change color
			send_input(":IN.0", 0x01, 0.5) -- CLEAR
		end
		if machine.system.name == "fexcelv" then
			send_input(":IN.0", 0x20, 0.5) -- OPTIONS
			sb_press_square(":board", 0.5, 2, 1) -- Sound on
			send_input(":IN.0", 0x01, 0.5) -- CLEAR
		end
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.0", 0x20, 0.5) -- OPTIONS
	sb_press_square(":board", 1, 3, 1)
	send_input(":IN.0", 0x01, 0.5) -- CLEAR
	emu.wait(0.5)
	machine.video.throttled = throttled_state
end

function interface.start_play(init)
	send_input(":IN.0", 0x02, 1) -- MOVE
end

function interface.clear_announcements()
	local root = machine.devices[":"]
	if not root then return end

	-- Modern non-deprecated node-object query layout
	local node2_pre = root:output("1.2")
	local node6_pre = root:output("1.6")
	
	local lastval2 = node2_pre and node2_pre:get() or 0
	local lastval6 = node6_pre and node6_pre:get() or 0
	
	emu.wait(0.3)
	
	local node2_post = root:output("1.2")
	local node6_post = root:output("1.6")
	
	local curval2 = node2_post and node2_post:get() or 0
	local curval6 = node6_post and node6_post:get() or 0
	
	if (lastval2 ~= curval2 or lastval6 ~= curval6) then
		send_input(":IN.0", 0x01, 1)
		emu.wait(1)
	end
end

function interface.is_selected(x, y)
	if (interface.opt_clear_announcements and x == 1 and y == 1) then
		interface.clear_announcements()
	end
	
	local root = machine.devices[":"]
	if not root then return false end
	
	-- Modern non-deprecated node-object query layout
	local r_node = root:output("0." .. tostring(y - 1))
	local c_node = root:output("1." .. tostring(x - 1))
	
	local r_val = r_node and r_node:get() or 0
	local c_val = c_node and c_node:get() or 0
	
	-- Reads the raw rank select lines and column bits natively in real-time
	return r_val ~= 0 and c_val ~= 0
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "spin", "Level", "6", "1", "12" },
		{ "check", "Clear announcements", "1" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 12) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
	if (name == "clear announcements") then
		interface.opt_clear_announcements = tonumber(value) == 1
	end
end

function interface.test_promotion(x, y)
	local function piece_led(port, code, x, y)
		local root = machine.devices[":"]
		if not root then return false end

		for n=1,8 do
			send_input(port, code, 0.5)
			for i=1,4 do
				-- FIXED: Modern non-deprecated node object API mapping format
				local r_node = root:output("0." .. tostring(y - 1))
				local c_node = root:output("1." .. tostring(x - 1))
				local r_val = r_node and r_node:get() or 0
				local c_val = c_node and c_node:get() or 0

				if r_val ~= 0 and c_val ~= 0 then
					return true
				end
				emu.wait(0.15)
			end
		end
		return false
	end

	if (interface.opt_clear_announcements) then
		interface.clear_announcements()
	end

	local p
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	emu.wait(1)
	
	if machine.system.name == "fexcelv" then
		send_input(":IN.0", 0x20, 0.5) -- OPTIONS
		sb_press_square(":board", 0.5, 2, 1) -- Voice off
		send_input(":IN.0", 0x01, 0.5) -- CLEAR
	end
	send_input(":IN.0", 0x40, 1) -- VERIFY

	if     piece_led(":IN.0", 0x20, x, y) then p = "Q"
	elseif piece_led(":IN.0", 0x04, x, y) then p = "N"
	elseif piece_led(":IN.0", 0x08, x, y) then p = "B"
	elseif piece_led(":IN.0", 0x10, x, y) then p = "R"
	else p = "Q"
	end

	send_input(":IN.0", 0x01, 0.5) -- CLEAR
	if machine.system.name == "fexcelv" then
		send_input(":IN.0", 0x20, 0.5) -- OPTIONS
		sb_press_square(":board", 0.5, 2, 1) -- Voice on
		send_input(":IN.0", 0x01, 0.5) -- CLEAR
	end
	machine.video.throttled = throttled_state
	return p
end

function interface.get_promotion(x, y)
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	if     (piece == "q") then send_input(":IN.0", 0x20, 1)
	elseif (piece == "r") then send_input(":IN.0", 0x10, 1)
	elseif (piece == "b") then send_input(":IN.0", 0x08, 1)
	elseif (piece == "n") then send_input(":IN.0", 0x04, 1)
	end
end

return interface

