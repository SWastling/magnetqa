// close any open images, reset results window etc...
run("Fresh Start");

// open a dialog box for the user to enter image filepaths and specify the slice and RF coil information
path = getDirectory("home")
Dialog.create("Geometric Linearity Distortion and Slice Width Test Details");
Dialog.addFile("Image:", path);
Dialog.addDirectory("Results directory:", path);
Dialog.addRadioButtonGroup("Slice orientation:", newArray("TRA", "COR", "SAG"), 1, 3, "TRA");
Dialog.addRadioButtonGroup("RF coil:", newArray("BC", "HC"), 1, 2, "BC");
Dialog.show();
im_fp = Dialog.getString();
output_dp = Dialog.getString();
slice_orientation = Dialog.getRadioButton;
rf_coil = Dialog.getRadioButton;

// create a directory to store the screenshots and csv results files
results_dp = output_dp + File.separator + "Analysis Results";
File.makeDirectory(results_dp);

// open the image and rename it im
open(im_fp);
rename("im");

Dialog.create("Direction of slice profiles");
Dialog.addRadioButtonGroup("Direction of slice profiles:", newArray("Horizontal", "Vertical"), 1, 2, "Horizontal");
Dialog.show();
sp_direction = Dialog.getRadioButton;

// find the locations of the nine rods in the image
// create a duplicate of im and then binarise it i.e. bright phantom with dark rods
run("Duplicate...", "title=im_bin");
rename("im_bin");
run("8-bit");
setAutoThreshold("Minimum dark no-reset");
run("Convert to Mask", "method=Minimum background=Dark calculate");

// create a duplicate of im_bin and fill the holes where the rods are filled in
run("Duplicate...", "title=im_bin_filled");
rename("im_bin_filled");
run("Fill Holes", "slice");

// calculate a difference image from im_bin and im_bin_filled i.e. dark background with bright rods
run("Calculator Plus", "i1=im_bin_filled i2=im_bin operation=[Subtract: i2 = (i1-i2) x k1 + k2] k1=1 k2=0 create");
rename("im_rods");
close("im_bin*");
selectWindow("im_rods");

// use Analyze Particles to find the location of the nine rods in im_rods
run("Set Measurements...", "centroid redirect=None decimal=3");
run("Analyze Particles...", "size=9-200 exclude clear");
close("im_rods");

// sort the rod labels and locations so that the first rod is on the top-left of the image and the ninth rod on the bottom right i.e.
// 0-1-2
// 3-4-5
// 6-7-8

rod_x_pos_arr = newArray(9);
rod_y_pos_arr = newArray(9);
position_index = newArray(9);
for (i = 0; i < 9; i++) {
	rod_x_pos_arr[i] = getResult("X", i);
	rod_y_pos_arr[i] = getResult("Y", i);
	position_index[i] = rod_y_pos_arr[i]*10 + rod_x_pos_arr[i];
}
sort_index=Array.rankPositions(position_index);

rod_x_pos_sorted_arr = newArray(9);
rod_y_pos_sorted_arr = newArray(9);
for (i = 0; i < 9; i++) {
	rod_x_pos_sorted_arr[i] = rod_x_pos_arr[sort_index[i]];
	rod_y_pos_sorted_arr[i] = rod_y_pos_arr[sort_index[i]];
}

// make three horizontal lines between rods 0 and 2, 3 and 5 and 6 and 8
selectWindow("im"); 
roiManager("reset")

// top horizontal line between rods 0 and 2
makeLine(rod_x_pos_sorted_arr[0], rod_y_pos_sorted_arr[0], rod_x_pos_sorted_arr[2], rod_y_pos_sorted_arr[2]);
roiManager("add");

// middle horizontal line between rods 3 and 5
makeLine(rod_x_pos_sorted_arr[3], rod_y_pos_sorted_arr[3], rod_x_pos_sorted_arr[5], rod_y_pos_sorted_arr[5]);
roiManager("add");

// bottom horizontal line between rods 6 and 8
makeLine(rod_x_pos_sorted_arr[6], rod_y_pos_sorted_arr[6], rod_x_pos_sorted_arr[8], rod_y_pos_sorted_arr[8]);
roiManager("add");

// make three vertical lines between rods 0 and 6, 1 and 7 and 2 and 8
// left vertical line between rods 0 and 6
makeLine(rod_x_pos_sorted_arr[0], rod_y_pos_sorted_arr[0], rod_x_pos_sorted_arr[6], rod_y_pos_sorted_arr[6]);
roiManager("add");

// middle vertical line between rods 1 and 7
makeLine(rod_x_pos_sorted_arr[1], rod_y_pos_sorted_arr[1], rod_x_pos_sorted_arr[7], rod_y_pos_sorted_arr[7]);
roiManager("add");

// right vertical line between rods 2 and 8
makeLine(rod_x_pos_sorted_arr[2], rod_y_pos_sorted_arr[2], rod_x_pos_sorted_arr[8], rod_y_pos_sorted_arr[8]);
roiManager("add");

// zoom the image to 200%
run("Set... ", "zoom=200 x=128 y=128");

// give the user the option to move the lines if needed
for (i = 0; i < 6; i++) {
	roiManager("select", i);
	waitForUser( "Move line if needed.\nPress OK when finished");
	roiManager("Update");
	wait(100);
}

// save the line lengths of the 6 lines to a csv file
roiManager("Select", newArray(0, 1, 2, 3, 4, 5));
run("Set Measurements...", "redirect=None decimal=3");
roiManager("Measure");
lin_dist_csv_fp = results_dp + File.separator + rf_coil + "_" + slice_orientation + "_GEOMETRIC_LINEARITY_DISTORTION.csv";
saveAs("Results", lin_dist_csv_fp);

// save the lines in a zip file
lin_dist_lines_fp = results_dp + File.separator + rf_coil + "_" + slice_orientation + "_GEOMETRIC_LINEARITY_DISTORTION_LINES.zip"
roiManager("save", lin_dist_lines_fp)

// zoom the image to 100%
run("Set... ", "zoom=100 x=128 y=128");

// save a screenshot of the lines overlaid on im
selectWindow("im");
roiManager("Show All");
run("Capture Image");
screengrab_lin_dist_fp = results_dp + File.separator + rf_coil + "_" + slice_orientation + "_GEOMETRIC_LINEARITY_DISTORTION_LINES.png";
saveAs("PNG", screengrab_lin_dist_fp);

// remove the lines used to measure the distortion-linearity
roiManager("Select", newArray(0, 1, 2, 3, 4, 5));
roiManager("Delete");

selectWindow("im");
if(sp_direction == "Horizontal"){

	// calculate positions of the centres of the ROIs to measure the horizontal slice profiles
	// i.e. centred between rods 1 and 4
	h_sp_top_x_centre = round((rod_x_pos_sorted_arr[1] + rod_x_pos_sorted_arr[4]) / 2); 
	h_sp_top_y_centre = round((rod_y_pos_sorted_arr[1] + rod_y_pos_sorted_arr[4]) / 2);

	// i.e. centred between rods 4 and 7
	h_sp_bottom_x_centre = round((rod_x_pos_sorted_arr[4] + rod_x_pos_sorted_arr[7]) / 2);
	h_sp_bottom_y_centre = round((rod_y_pos_sorted_arr[4] + rod_y_pos_sorted_arr[7]) / 2);

	// create the two horizontal slice profile ROIs
	// top
	makeRectangle(h_sp_top_x_centre - 60, h_sp_top_y_centre - 5, 120, 10);
	roiManager("add");
	// bottom
	makeRectangle(h_sp_bottom_x_centre - 60, h_sp_bottom_y_centre - 5, 120, 10);
	roiManager("add");

	// get the horizontal profiles
	run("Clear Results");
	roiManager("Select", 0);
	profile_1 = getProfile();

	run("Clear Results");
	roiManager("Select", 1);
	profile_2 = getProfile();
}
else{
	// calculate positions of the centres of the ROIs to measure the vertical slice profiles
	// i.e. centred between rods 3 and 4
	v_sp_left_x_centre = round((rod_x_pos_sorted_arr[3] + rod_x_pos_sorted_arr[4]) / 2);
	v_sp_left_y_centre = round((rod_y_pos_sorted_arr[3] + rod_y_pos_sorted_arr[4]) / 2);

	// i.e. centred between rods 4 and 5
	v_sp_right_x_centre = round((rod_x_pos_sorted_arr[4] + rod_x_pos_sorted_arr[5]) / 2);
	v_sp_right_y_centre = round((rod_y_pos_sorted_arr[4] + rod_y_pos_sorted_arr[5]) / 2);

	// create the two vertical slice profile ROIs
	// left
	makeRectangle(v_sp_left_x_centre - 5, v_sp_left_y_centre - 60, 10, 120);
	roiManager("add");
	//right
	makeRectangle(v_sp_right_x_centre - 5, v_sp_right_y_centre - 60, 10, 120);
	roiManager("add");

	// get the vertical profiles
	run("Clear Results");
	roiManager("Select", 0);
	// set alt key down for vertical profile of a rectangular selection
	setKeyDown("alt");
	profile_1 = getProfile();
	setKeyDown("none");

	run("Clear Results");
	roiManager("Select", 1);
	// set alt key down for vertical profile of a rectangular selection
	setKeyDown("alt");
	profile_2 = getProfile();
	setKeyDown("none");

}

// save the slice profiles to csv files
run("Clear Results");
for (i=0; i < profile_1.length; i++)
	setResult("Value", i, profile_1[i]);
updateResults;
sp_1_csv_fp = results_dp + File.separator + rf_coil + "_" + slice_orientation + "_SLICE_WIDTH_1.csv";
saveAs("Results", sp_1_csv_fp);

run("Clear Results");
for (i=0; i < profile_2.length; i++)
	setResult("Value", i, profile_2[i]);
updateResults;
sp_2_csv_fp = results_dp + File.separator + rf_coil + "_" + slice_orientation + "_SLICE_WIDTH_2.csv";
saveAs("Results", sp_2_csv_fp);

// save the slice profile ROIs in a zip file
sp_rois_fp = results_dp + File.separator + rf_coil + "_" + slice_orientation + "_SLICE_WIDTH_ROIs.zip";
roiManager("save", sp_rois_fp);

// save a screenshot of the slice profile ROIs overlaid on im
roiManager("Show All");
run("Capture Image");
screengrab_slice_profile_fp = results_dp + File.separator + rf_coil + "_" + slice_orientation + "_SLICE_WIDTH_ROIs.png";
saveAs("PNG", screengrab_slice_profile_fp);

// close any open images, reset results window etc...
run("Fresh Start");

