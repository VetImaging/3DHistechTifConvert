/* Macro for converting extended tifs from Histech3D-slidescanner (vetmeduni-pathology) to jpgs or tifs
 * including optional resizing the images
 * input: mrxs to tiled tiff converted images with 3DHistech case converter
 * output: tif or jpg
 * VetImaging / VetCore / Vetmeduni Vienna
 */

/* Create interactive Window to set variables for 
 * input/output folder, input/output suffix, scale factor, subfolder-processing
 */
#@ File (label = "Input directory", style = "directory") 		input_folder
#@ File (label = "Output directory", style = "directory") 		output_folder
#@ String (label = "File suffix input", choices={".tif"}) 		suffix_in
#@ String (label = "File suffix output", choices={".jpg",".tif"}) 	suffix_out
#@ Integer (label = "Scale factor (%)", value=100) 			scale_percentage
#@ String (label = "Include subfolders", choices={"no","yes"}) 		subfolders

run("Collect Garbage");

processFolder(input_folder);


// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input_folder) {
	filelist = getFileList(input_folder);
	filelist = Array.sort(filelist);
	for (i = 0; i < filelist.length; i++) {
		// only precess recursion for subfolders if option "Include subfolders" is true
		if(subfolders=="yes"){
		if(File.isDirectory(input_folder + File.separator + filelist[i]))
			processFolder(input_folder + File.separator + filelist[i]);}
			
		// for images with correct suffix proceed with function processFile
		if(endsWith(filelist[i], suffix_in))
			processFile(input_folder, output_folder, filelist[i]);
		run("Close All");
		run("Collect Garbage");
	}
}

// function to open file, convert to RGB, rescale and save as defined in "suffix_out"
function processFile(input_folder, output_folder, file) {
    run("Bio-Formats Windowless Importer", "open=[" + input_folder + "\\" + file +"]");
    run("RGB Color");
	scale_factor=scale_percentage/100;
	scaled_width=round(scale_factor * getWidth());
	scaled_height=round(scale_factor * getHeight());
	run("Scale...", "x=" + scale_factor + " y="+ scale_factor +" width="+ scaled_width +" height=" + scaled_height +" interpolation=Bilinear average");
		
	if (endsWith(getTitle(),"-5060C-ZERO_Extended.tif (RGB)")) 
		file = replace(file, "-5060C-ZERO_Extended.tif", "");

	if (endsWith(getTitle(),"_Wholeslide_Default_Extended.tif (RGB)")) 
		file = replace(file, "_Wholeslide_Default_Extended.tif", "");
	
	if(suffix_out==".jpg") 
		saveAs("Jpeg", output_folder + "\\" + file + ".jpg");
		
	if(suffix_out==".tif") 
		saveAs("Tiff", output_folder  + "\\" + file + ".tif");
}
