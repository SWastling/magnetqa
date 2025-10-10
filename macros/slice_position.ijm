// close any open images, reset results window etc...
run("Fresh Start");

// open a dialog box for the user to enter image filepaths and specify the slice and RF coil information
path = getDirectory("home")
Dialog.create("Slice Position Test Details");
Dialog.addDirectory("Directory containing DICOM images:", path);
Dialog.addDirectory("Results directory:", path);
Dialog.addChoice("Slice orientation:", newArray("TRA", "COR", "SAG"));
Dialog.addChoice("RF coil:", newArray("BC", "HC"));
Dialog.show();
im_dp = Dialog.getString();
output_dp = Dialog.getString();
slice_orientation = Dialog.getChoice();
rf_coil = Dialog.getChoice();

// create a directory to store the screenshots and csv results files
results_dp = output_dp + File.separator + "Analysis Results";
File.makeDirectory(results_dp);

temp_screenshots_dp = results_dp + File.separator + rf_coil + "_" + slice_orientation + "_SLICE_POSITION_LINES"
File.makeDirectory(temp_screenshots_dp);

// open the set of DICOM files in im_dp and rename them im
open(im_dp);
rename("im");

// create a csv file to store the results of the slice position measurements
slice_position_results_csv_fp = results_dp + File.separator + rf_coil + "_" + slice_orientation + "_SLICE_POSITION.csv";
f_slice_position_csv = File.open(slice_position_results_csv_fp);
print(f_slice_position_csv, "Slice,Distance (mm),Mean Test Object Distance (mm)");

// define the vertices of the default polygon to encompass the 6 rods in the phantom
polygon_x1 = 200;
polygon_y1 = 56;
polygon_x2 = 56;
polygon_y2 = 56;
polygon_x3 = 46;
polygon_y3 = 128;
polygon_x4 = 56;
polygon_y4 = 200;
polygon_x5 = 200;
polygon_y5 = 200;
polygon_x6 = 210;
polygon_y6 = 128; 

// loop over the slices, finding the 6 rods in each
numberOfStackSlices = nSlices;
for (sl = 1; sl < numberOfStackSlices + 1; sl++) {
	selectImage("im");
	setSlice(sl);
	
	// force the ROI manager to stop showing any pre-existing ROIs
	roiManager("Show All");
	roiManager("Show None");

	// prompt the user 
	if (getBoolean("Are the 4 parallel rods at the edge and the 2 angled rods in the centre of the phantom clearly visible?")){
		
		run("Make Substack...", "slices="+sl);
		rename("im_bin");
		
		// zoom the image to 200%
		run("Set... ", "zoom=200 x=128 y=128");

		makePolygon(polygon_x1, polygon_y1, polygon_x2, polygon_y2, polygon_x3, polygon_y3, polygon_x4, polygon_y4, polygon_x5, polygon_y5, polygon_x6, polygon_y6);
		roiManager("Add");
		waitForUser("Modify ROI to include all 6 rods. \nPress OK when finished");

		run("Clear Outside", "slice");
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

		// use Analyze Particles to find the location of the six rods in im_rods
		run("Set Measurements...", "centroid redirect=None decimal=3");
		run("Analyze Particles...", "size=1-30 circularity=0.01-1.00 exclude clear");
		close("im_rods");
		
		if (nResults == 6){
			// if Analyse Particles found six rods
			
			// sort the rod labels and locations so that the first rod is on the top-left of the image and the sixth rod on the bottom right i.e.
			// 0-1
			// 2-3
			// 4-5

			rod_x_pos_arr = newArray(6);
			rod_y_pos_arr = newArray(6);
			position_index = newArray(6);
			for (r = 0; r < 6; r++) {
				rod_x_pos_arr[r] = getResult("X", r);
				rod_y_pos_arr[r] = getResult("Y", r);
				position_index[r] = rod_y_pos_arr[r]*10 + rod_x_pos_arr[r];
			}
			sort_index=Array.rankPositions(position_index);

			rod_x_pos_sorted_arr = newArray(6);
			rod_y_pos_sorted_arr = newArray(6);
			for (r = 0; r < 6; r++) {
				rod_x_pos_sorted_arr[r] = rod_x_pos_arr[sort_index[r]];
				rod_y_pos_sorted_arr[r] = rod_y_pos_arr[sort_index[r]];
			}

		} else {
			// if Analyse Particles didn't find six rods, set their positions to default values, the user will be prompted to check the line positions later
			rod_x_pos_sorted_arr = newArray(65, 190, 65, 190, 65, 190);
			rod_y_pos_sorted_arr = newArray(63, 63, 130, 120, 185, 185);
		}
			
		// make three lines between rods 0 and 1, 2 and 3 and 4 and 5
		selectWindow("im");
		// zoom the image to 200%
		run("Set... ", "zoom=200 x=128 y=128");
		roiManager("reset")

		// make a horizontal line between rods 0 and 1 i.e the top 2 parallel rods
		makeLine(rod_x_pos_sorted_arr[0], rod_y_pos_sorted_arr[0], rod_x_pos_sorted_arr[1], rod_y_pos_sorted_arr[1]);
		roiManager("add");
		roiManager("select", 0);
		waitForUser( "Modify line as required to go\nthrough centres of top 2 parallel rods.\nPress OK when finished");
		wait(100);
		roiManager("Update");
		wait(100);
		getLine(x0, y0, x1, y1, lineWidth);

		// make a line between rods 2 and 3 i.e. the central angled rods
		makeLine(rod_x_pos_sorted_arr[2], rod_y_pos_sorted_arr[2], rod_x_pos_sorted_arr[3], rod_y_pos_sorted_arr[3]);
		roiManager("add");
		roiManager("select", 1);
		waitForUser( "Modify line as required to go\nthrough centres of middle 2 angled rods.\nPress OK when finished");
		wait(100);
		roiManager("Update");
		wait(100);
		getLine(x2, y2, x3, y3, lineWidth);
		
		// make a horizontal line between rods 4 and 5 i.e the bottom 2 parallel rods
		makeLine(rod_x_pos_sorted_arr[4], rod_y_pos_sorted_arr[4], rod_x_pos_sorted_arr[5], rod_y_pos_sorted_arr[5]);
		roiManager("add");
		roiManager("select", 2);
		waitForUser( "Modify line as required to go\nthrough centres of bottom 2 parallel rods.\nPress OK when finished");
		wait(100);
		roiManager("Update");
		wait(100);
		getLine(x4, y4, x5, y5, lineWidth);

		// zoom the image to 100%
		selectWindow("im");
		run("Set... ", "zoom=100 x=128 y=128");
		roiManager("Show All")
		run("Capture Image");
		screengrab_fp = temp_screenshots_dp + File.separator + "SL_" + String.pad(sl,2) + ".png";
		saveAs("PNG", screengrab_fp);

		run("Set Measurements...", "redirect=None decimal=3");
		roiManager("Select", newArray(0, 1, 2));
		roiManager("Measure");
		
		distance_between_top_parallel_rods = getResult("Length", 0);
		distance_between_angled_rods = getResult("Length", 1);
		distance_between_bottom_parallel_rods = getResult("Length", 2);
		mean_distance_between_parallel_rods = (distance_between_top_parallel_rods + distance_between_bottom_parallel_rods) / 2;

		// save the distances to the csv file
		print(f_slice_position_csv, sl + "," + d2s(distance_between_angled_rods,3) + "," + d2s(mean_distance_between_parallel_rods,3));

		run("Clear Results");		
		roiManager("reset");

		// update the coordinates of the polygon used to select the six rods in the next slice	
		polygon_x1 = x1 + 5;
		polygon_y1 = y1 - 5;
		polygon_x2 = x0 - 5;
		polygon_y2 = y0 - 5;
		polygon_x3 = 55;
		polygon_y3 = y2;
		polygon_x4 = x4 - 5;
		polygon_y4 = y4 + 5;
		polygon_x5 = x5 + 5;
		polygon_y5 = y5 + 5;
		polygon_x6 = 200;
		polygon_y6 = y3;

	} else {
		print(f_slice_position_csv, sl + ",," );

		run("Capture Image");
		screengrab_fp = temp_screenshots_dp + File.separator + "SL_" + String.pad(sl,2) + ".png";
		saveAs("PNG", screengrab_fp);
	}
}
File.close(f_slice_position_csv)
close("im")

run("Images to Stack", "use");
run("Make Montage...", "columns=6 rows=5 scale=1 label");
screengrab_montage_fp = results_dp + File.separator + rf_coil + "_" + slice_orientation + "_SLICE_POSITION_LINES.png";
saveAs("PNG", screengrab_montage_fp);

File.delete(temp_screenshots_dp)




