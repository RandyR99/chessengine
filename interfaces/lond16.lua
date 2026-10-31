interface = load_interface("lyon16") -- Lyon program family: info display

interface.level = "NORML 01"

function interface.get_module()
	return "Mephisto London (16 Bit)"
end

function interface.get_author()
	return "Richard Lang"
end

function interface.stop_play()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":KEY3", 0x0200, 0.5)	-- CL
	send_input(":KEY3", 0x0200, 0.5)	-- CL
	send_input(":KEY1", 0x0200, 0.5)	-- ENT
	machine.video.throttled = throttled_state
end

function interface.get_options()
	return {
		{ "string", "Level", "NORML 01" },
	}
end

return interface
