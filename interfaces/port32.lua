interface = load_interface("alm32")

function interface.set_pos(mode)
	if mode == 0 then
		if (machine.ioport.ports[":FAKE"]:read() ~= 0x01) then
			machine.ioport.ports[":FAKE"]:field(0x01):set_value(1)
			machine:soft_reset()
			emu.wait(1)
		end
		send_input(":KEY1", 0x8000, 0.5)	-- CL
		send_input(":KEY1", 0x8000, 0.5)	-- CL
		send_input(":KEY2", 0x4000, 0.5)	-- DOWN
		send_input(":KEY2", 0x4000, 0.5)	-- DOWN
		send_input(":KEY3", 0x8000, 0.5)	-- ENT
		send_input(":KEY1", 0x4000, 0.5)	-- RIGHT
		send_input(":KEY3", 0x8000, 0.5)	-- ENT
		send_input(":KEY3", 0x4000, 0.5)	-- LEFT
		return (":board:board")
	else
		send_input(":KEY3", 0x8000, 0.5)	-- ENT
		if mode == -1 then
			send_input(":KEY2", 0x4000, 0.5)	-- DOWN
		end
		send_input(":KEY1", 0x8000, 0.5)	-- CL
		send_input(":KEY1", 0x8000, 0.5)	-- CL
	end
end

function interface.stop_play()
	send_input(":KEY1", 0x8000, 0.5)	-- CL
	send_input(":KEY1", 0x8000, 0.5)	-- CL
	send_input(":KEY3", 0x8000, 0.5)	-- ENT
end

return interface
