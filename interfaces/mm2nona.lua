interface = load_interface("rebel5")

function interface.get_module()
	return "Mephisto MM II Nona"
end

function interface.get_author()
	return "Frans Morsch"
end

-- the Nona program keeps its info elsewhere than rebel5 (not found)
interface.show_info = nil

return interface
