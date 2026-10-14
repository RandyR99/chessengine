interface = load_interface("sdtor")

function interface.get_module()
	return "CXG Sphinx Commander"
end

function interface.get_author()
	return "Frans Morsch"
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 0.5, x, y, event)
	if (event == "put") then
		-- magnet sensors (250 ms delay): the ROM loses the next move if a piece
		-- is lifted too soon after it has registered the last one
		emu.wait(1)
	end
end

return interface
