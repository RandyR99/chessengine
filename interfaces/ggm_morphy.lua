interface = load_interface("ggm_boris25")

function interface.get_module()
	return "GGM Morphy Encore"
end

function interface.get_author()
	return "John Aker"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.3", 0x01, 0.5) -- LEVEL
	emu.wait(0.5)
	if (interface.level <= 4) then
		send_input(":IN.0", 1 << interface.level, 0.5)
	elseif (interface.level <= 8) then
		send_input(":IN.1", 1 << (interface.level - 5), 0.5)
	end
	send_input(":IN.3", 0x10, 0.5) -- ENTER
	emu.wait(0.5)
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	interface.turn = true
	interface.color = "B"
	emu.wait(4)
	machine.video.throttled = throttled_state
	interface.cur_level = 1
	interface.setlevel()
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "0", "8" },
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

return interface
