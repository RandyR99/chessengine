interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

local function led_on(name)
	local led = machine.devices[":"]:output(name)
	return led ~= nil and led:get() ~= 0
end

interface.level = 1
interface.cur_level = nil

function interface.get_module()
	if machine.system.name == "chessmst" then
		return "VEB Chess-Master"
	elseif machine.system.name == "chessmsta" then
		return "VEB Chess-Master v2"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Dieter Schultze & Rüdiger Worbs"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	send_input(":IN.0", 0x40, 1) -- Level
	send_input(":IN.0", 0x80 >> interface.level, 1)
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	send_input(":IN.0", 0x80, 1) 		-- New Game
	emu.wait(2)
	machine.video.throttled = throttled_state
	interface.cur_level = 1
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.1", 0x02, 1) -- Reset
		return (":board")
	else
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		local ram = machine.devices[":maincpu"].spaces["program"]
		local fig = {0x81,0x82,0x83,0x84,0x85,0x86,0x00,0x06,0x05,0x04,0x03,0x02,0x01}
		local adr = 0x3715
		local brd = {{  3, 5, 4, 2, 1, 4, 5, 3 },
				     {  6, 6, 6, 6, 6, 6, 6, 6 },
				     {  0, 0, 0, 0, 0, 0, 0, 0 },
				     {  0, 0, 0, 0, 0, 0, 0, 0 },
				     {  0, 0, 0, 0, 0, 0, 0, 0 },
			    	 {  0, 0, 0, 0, 0, 0, 0, 0 },
				     { -6,-6,-6,-6,-6,-6,-6,-6 },
				     { -3,-5,-4,-2,-1,-4,-5,-3 }}
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, y)
				local z = fig[p + 7]
				if p ~= 0 and p ~= brd[y][x] then
					z = z|0x40
				end
				ram:write_u8(adr + 10 * (y - 1) + x - 1, z)
			end
		end
		if mode == 1 then
			ram:write_u8(0x3415,0x80)
			ram:write_u8(0x3416,0x00)
		else
			ram:write_u8(0x3415,0x00)
			ram:write_u8(0x3416,0x80)
		end
		send_input(":IN.0", 0x10, 1) -- Board
		send_input(":IN.0", 0x10, 1) -- Board
		machine.video.throttled = throttled_state
	end
end

function interface.edit_game(on)
	if on then
		send_input(":IN.0", 0x04, 1) -- Referee
	else
		send_input(":IN.0", 0x20, 1) -- Color
	end
end

function interface.start_play(init)
	send_input(":IN.0", 0x20, 1) 		-- Color
end

function interface.stop_play()
	send_input(":IN.1", 0x01, 1) 		-- Halt
end

local led_snap = {}

function interface.is_selected(x, y)
	-- the computer's move is shown with a blinking destination led. If a poll sees only
	-- the source, the piece gets lifted first, and an en passant destination is then
	-- never shown again. So sample the leds for 0.4 seconds at the start of each poll.
	if x == 1 and y == 1 then
		led_snap = {}
		for i = 1, 8 do
			for sy = 1, 8 do
				for sx = 1, 8 do
					if led_on(tostring(sx - 1) .. "." .. tostring(sy - 1)) then
						led_snap[sy * 8 + sx] = true
					end
				end
			end
			emu.wait(0.05)
		end
	end
	return led_snap[y * 8 + x] == true
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "0", "7" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 0 or level > 7) then
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
