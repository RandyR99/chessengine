interface = load_interface("glasgow")
-- the Amsterdam/Dallas/Roma program keeps its search information as text in RAM: amsterd.lua reads it
local amsterdam = load_interface("amsterd")
interface.show_info = amsterdam.show_info
interface.info_every = amsterdam.info_every

function interface.get_module()
	return "Mephisto Amsterdam v2"
end

function interface.get_author()
	return "Richard Lang"
end

return interface
