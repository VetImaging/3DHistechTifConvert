/* Macro for converting 
 * extended tifs from Histech3D-slidescanner (vetmeduni-pathology), jpg, png, tiff
 * optional resizing and tiling if the images
 * input: jpg, png, tif
 * output: jpg, png, tif
 * SK / VetImaging / VetCore / Vetmeduni Vienna 2020
 */

/* Create interactive Window to set variables for 
 * input/output folder, input/output suffix, scale factor, subfolder-processing
 */
#@ String (visibility=MESSAGE, value="Choose your files and parameter", required=false) msg1
#@ String (visibility=MESSAGE, value="exported 3DHistech Scans = .tif", required=false) msg2
#@ File (label = "Input directory", style = "directory") 		input_folder
#@ File (label = "Output directory", style = "directory") 		output_folder
#@ String (label = "File suffix input", choices={".jpg",".png",".tif",".jpeg",".tiff"}, style="radioButtonHorizontal") 	suffix_in
#@ String (label = "File suffix output", choices={".jpg",".png",".tif"}, style="radioButtonHorizontal") 	suffix_out
#@ Integer (label = "Scale factor (%)", value=100) 			scale_percentage
#@ String (label = "Tile image", choices={"1", "2x2","3x3","4x4"}, style="radioButtonHorizontal") 	image_tiles
#@ String (label = "Include subfolders", choices={"no","yes"}, style="radioButtonHorizontal") 		subfolders
#@ String (label = "Run in silent batch mode", choices={"no","yes"}, style="radioButtonHorizontal") 	runBatch

run("Collect Garbage");

if(runBatch=="yes") setBatchMode(true); 

processFolder(input_folder);


// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input_folder) {
	filelist = getFileList(input_folder);
	filelist = Array.sort(filelist);
	for (i = 0; i < filelist.length; i++) {
		
		// process recursion for subfolders if option "Include subfolders" is true
		if(subfolders=="yes"){
		if(File.isDirectory(input_folder + File.separator + filelist[i]))
			processFolder(input_folder + File.separator + filelist[i]);}
			
		// for images with correct suffix proceed with function processFile()
		if(endsWith(filelist[i], suffix_in))
			processFile(input_folder, output_folder, filelist[i]);
		
		run("Close All");
		run("Collect Garbage");
	}
}


// FUNCTION: open file, convert to RGB, rescale and save as defined in "suffix_out"
function processFile(input_folder, output_folder, file) {

	if(suffix_in==".tif"||suffix_in==".tiff"){
    	run("Bio-Formats Windowless Importer", "open=[" + input_folder + "\\" + file +"]");
    	run("RGB Color");
	}

	if(suffix_in==".jpg"||suffix_in==".jpeg"||suffix_in==".png"){
    	open(input_folder + "\\" + file);
	}
	id = getImageID();
	// scale if value not 100%
	if (scale_percentage!=100) scale_image(scale_percentage, id);

	// delete unwanted strings in filename
	if (endsWith(getTitle(),"_Default_Extended.tif (RGB)-1")) 
		{file = replace(file, "_Default_Extended.tif (RGB)-1", "");} 
	else if (endsWith(getTitle(),"_Wholeslide_Default_Extended.tif (RGB)-1"))
		{file = replace(file, "_Wholeslide_Default_Extended.tif (RGB)-1", "");}
	else if (endsWith(getTitle()," (RGB)-1")) 
		{file = replace(file, " (RGB)-1", "");}

	file = replace(file, suffix_in, "");

	if (image_tiles!="1") tile_image(id, file);
	else {		
		if(suffix_out==".jpg") 
			saveAs("Jpeg", output_folder + "\\" + file + ".jpg");

		if(suffix_out==".png") 
			saveAs("PNG", output_folder + "\\" + file + ".png");
		
		if(suffix_out==".tif") 
			saveAs("Tiff", output_folder  + "\\" + file + ".tif");
	}
}




//FUNCTION: tile images; input: image title; output: saved files in defined fileformat
function tile_image(tile_file, title){
	if (image_tiles=="2x2") n=2; 
	if (image_tiles=="3x3") n=3; 
	if (image_tiles=="4x4") n=4;
	id = getImageID();

	getLocationAndSize(locX, locY, sizeW, sizeH);
	width = getWidth();
	height = getHeight();
	tileWidth = width / n;
	tileHeight = height / n;
	for (y = 0; y < n; y++) {
	offsetY = y * height / n;
 		for (x = 0; x < n; x++) {
			offsetX = x * width / n;
			selectImage(id);
			run("Duplicate...", "title=" + " [" + x + "," + y + "]"); 
			makeRectangle(offsetX, offsetY, tileWidth, tileHeight);
 			run("Crop");
			tile_file = title + " [" + x + "," + y + "]";

	if(suffix_out==".jpg") 
		saveAs("Jpeg", output_folder + "\\" + tile_file + ".jpg");

	if(suffix_out==".png") 
		saveAs("PNG", output_folder + "\\" + tile_file + ".png");
		
	if(suffix_out==".tif") 
		saveAs("Tiff", output_folder  + "\\" + tile_file + ".tif");

	close();
		}
	}
selectImage(id); 
close();
}

//FUNCTION: scale image; input: scale factor as value and Image-id; output: scaled image to go on with
function scale_image(scale_percentage, id){
			selectImage(id);
	scale_factor=scale_percentage/100;
	scaled_width=round(scale_factor * getWidth());
	scaled_height=round(scale_factor * getHeight());
	run("Scale...", "x=" + scale_factor + " y="+ scale_factor +" width="+ scaled_width +" height=" + scaled_height +" interpolation=Bilinear average create");

}
