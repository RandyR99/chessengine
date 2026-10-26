interface = load_interface("alm16")

function interface.get_module()
	return "Mephisto Portorose (16 Bit)"
end

function interface.get_author()
	return "Richard Lang"
end

-- Portorose 1.01 can't use the Bavaria board (see modular.cpp): keep the magnet board
-- and enter the pieces in SETUP > CHGBD (symbol via RIGHT/LEFT, colour via DOWN, then lift+replace)
local function set_pos_magnets(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		if (machine.ioport.ports[":FAKE"]:read() ~= 0x00) then
			machine.ioport.ports[":FAKE"]:field(0x01):set_value(0)
			machine:soft_reset()
			emu.wait(1)
		end
		send_input(":KEY3", 0x0200, 0.5)	-- CL
		send_input(":KEY3", 0x0200, 0.5)	-- CL
		send_input(":KEY3", 0x0100, 0.5)	-- DOWN
		send_input(":KEY3", 0x0100, 0.5)	-- DOWN
		send_input(":KEY1", 0x0200, 0.5)	-- ENT
		send_input(":KEY2", 0x0100, 0.5)	-- RIGHT
		send_input(":KEY1", 0x0200, 0.5)	-- ENT
		send_input(":KEY1", 0x0100, 0.5)	-- LEFT
		machine.video.throttled = throttled_state
		return (":board:board")
	else
		send_input(":KEY1", 0x0200, 0.5)	-- ENT
		local ddram = emu.item(machine.devices[':display:hd44780'].items['0/m_ddram'])
		-- selected symbol: 0x41 colour (0x0e white, 0x0f black), 0x42 piece (0x08 king .. 0x0d pawn)
		local function select_colour(white)
			for i = 1, 3 do
				if ddram:read(0x41) == (white and 0x0e or 0x0f) then
					return
				end
				send_input(":KEY3", 0x0100, 0.5)	-- DOWN
			end
		end
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					-- lifting a piece changes the selected symbol, so select it while the piece is up
					local square = machine.ioport.ports[":board:board:RANK." .. tostring(9 - y)]:field(1 << (x - 1))
					sb_set_ui(":board:board", 0x0001, 1)
					square:set_value(1)
					emu.wait(1)	-- the machine shows the lifted square's symbol late; select after that
					for tries = 1, 3 do
						select_colour(p > 0)
						for i = 1, 6 do
							local n = 0x07 + math.abs(p) - ddram:read(0x42)
							if n == 0 then
								break
							elseif n % 6 <= 3 then
								send_input(":KEY2", 0x0100, 0.5)	-- RIGHT
							else
								send_input(":KEY1", 0x0100, 0.5)	-- LEFT
							end
						end
						emu.wait(0.5)
						if ddram:read(0x41) == (p > 0 and 0x0e or 0x0f) and ddram:read(0x42) == 0x07 + math.abs(p) then
							break
						end
					end
					square:set_value(0)
					emu.wait(1)
					sb_set_ui(":board:board", 0x0001, 0)
				end
			end
		end
		select_colour(mode > 0)
		send_input(":KEY3", 0x0200, 0.5)	-- CL
		send_input(":KEY3", 0x0200, 0.5)	-- CL
	end
	machine.video.throttled = throttled_state
end

function interface.set_pos(mode)
	if machine.system.name == "port16" then
		return set_pos_magnets(mode)
	end
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		if (machine.ioport.ports[":FAKE"]:read() ~= 0x01) then
			machine.ioport.ports[":FAKE"]:field(0x01):set_value(1)
			machine:soft_reset()
			emu.wait(1)
		end
		send_input(":KEY3", 0x0200, 0.5)	-- CL
		send_input(":KEY3", 0x0200, 0.5)	-- CL
		send_input(":KEY3", 0x0100, 0.5)	-- DOWN
		send_input(":KEY3", 0x0100, 0.5)	-- DOWN
		send_input(":KEY1", 0x0200, 0.5)	-- ENT
		send_input(":KEY2", 0x0100, 0.5)	-- RIGHT
		send_input(":KEY1", 0x0200, 0.5)	-- ENT
		send_input(":KEY1", 0x0100, 0.5)	-- LEFT
		machine.video.throttled = throttled_state
		return (":board:board")
	else
		send_input(":KEY1", 0x0200, 0.5)	-- ENT
		if mode == -1 then
			send_input(":KEY3", 0x0100, 0.5)	-- DOWN
		end
		send_input(":KEY3", 0x0200, 0.5)	-- CL
		send_input(":KEY3", 0x0200, 0.5)	-- CL
	end
	machine.video.throttled = throttled_state
end

function interface.stop_play()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":KEY3", 0x0200, 0.5)	-- CL
	send_input(":KEY3", 0x0200, 0.5)	-- CL
	send_input(":KEY1", 0x0200, 0.5)	-- ENT
	machine.video.throttled = throttled_state
end

return interface
