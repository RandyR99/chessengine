interface = load_interface("port16")
-- the Lyon program has the programmable info display (lyon32.lua), here with the 16 bit module's keys
local lyon = load_interface("lyon32")
local setup_machine = interface.setup_machine
function interface.setup_machine()
	setup_machine()
	lyon.info_display({ cl = { ":KEY3", 0x0200 }, right = { ":KEY2", 0x0100 }, down = { ":KEY3", 0x0100 }, ent = { ":KEY1", 0x0200 } })
end
interface.show_info = lyon.show_info
interface.info_every = lyon.info_every

interface.level = "NORML 01"

function interface.get_module()
	return "Mephisto Lyon (16 Bit)"
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
