interface = load_interface("im01")

interface.turn = true
interface.level = 2
interface.cur_level = nil

function interface.get_module()
	return "Elektronika IM-01T"
end

function interface.get_author()
	return "Vladimir Petrenko"
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	interface.turn = true
	machine.ioport.ports[":IN.4"]:field(0x01):set_value(1)  -- PREFIX on
	emu.wait(0.5)
	send_input(":IN.5", 0x01, 1) -- RESET
	emu.wait(0.5)
	machine.ioport.ports[":IN.4"]:field(0x01):set_value(0)  -- PREFIX off
	emu.wait(0.5)
	machine.video.throttled = throttled_state
	interface.cur_level = 2
	interface.setlevel()
end

function interface.get_options()
	return {
		{ "spin", "Level", "2", "1", "7" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 7) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

return interface
