interface = load_interface("arb_sargon25")

function interface.get_module()
	return "Sargon 3.5 GMS"
end

function interface.get_author()
	return "Dan & Kathe Spracklen"
end

return interface
