local module = machine.images[':cartslot'].filename
if (module == "boris25") then
	return load_interface("ggm_boris25")
elseif (module == "capa") then
	return load_interface("ggm_capa")
elseif (module == "capas") then
	return load_interface("ggm_capas")
elseif (module == "gruen") then
	return load_interface("ggm_gruen")
elseif (module == "gruens") then
	return load_interface("ggm_gruens")
elseif (module == "morphy") then
	return load_interface("ggm_morphy")
elseif (module == "sandy") then
	return load_interface("ggm_sandy")
elseif (module == "steinitz" or module == "steinitza" or module == "steinitzb") then
	return load_interface("ggm_steinitz")
end

return nil
