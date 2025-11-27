// close any open images, reset results window etc...
run("Fresh Start");

// open a dialog box for the user to enter image filepaths and specify the slice and RF coil information
path = getDirectory("home")
Dialog.create("SNR and Uniformity Test Details");
Dialog.addFile("First image:", path);
Dialog.addFile("Second image:", path);
Dialog.addDirectory("Results directory:", path);
Dialog.addRadioButtonGroup("Slice orientation:", newArray("TRA", "COR", "SAG"), 1, 3, "TRA");
Dialog.addRadioButtonGroup("RF coil:", newArray("BC", "HC"), 1, 2, "BC");
Dialog.show();
im_1_fp = Dialog.getString();
im_2_fp = Dialog.getString();
output_dp = Dialog.getString();
slice_orientation = Dialog.getRadioButton;
rf_coil = Dialog.getRadioButton;

// Define directory paths
analysis_results_dp = output_dp + File.separator + "Analysis_Results";
snr_results_dp = analysis_results_dp + File.separator + "SNR";
uniformity_results_dp = analysis_results_dp + File.separator + "Uniformity";

// Define file paths
snr_results_fp_stem = snr_results_dp + File.separator + rf_coil + "_" + slice_orientation + "_SNR";
snr_results_csv_fp = snr_results_fp_stem + ".csv";
snr_rois_fp = snr_results_fp_stem + "_ROIs.zip";
screengrab_im_1_rois_fp = snr_results_fp_stem + "_Image_1_ROIs.png";
screengrab_im_2_rois_fp = snr_results_fp_stem + "_Image_2_ROIs.png";
screengrab_diff_im_rois_fp = snr_results_fp_stem + "_Difference_Image_ROIs.png";
screengrab_snr_images_with_rois_fp = snr_results_fp_stem + "_Images_with_ROIs.png";

uni_results_fp_stem = uniformity_results_dp + File.separator + rf_coil + "_" + slice_orientation + "_UNIFORMITY";
horizontal_uniformity_results_csv_fp = uni_results_fp_stem + "_HORIZONTAL.csv";
vertical_uniformity_results_csv_fp = uni_results_fp_stem + "_VERTICAL.csv";
uniformity_rois_fp = uni_results_fp_stem + "_ROIs.zip";
screengrab_im_1_uniformity_rois_fp = uni_results_fp_stem + "_ROIs.png";

// Check if results already exist
if (File.exists(snr_results_csv_fp))
	exit(snr_results_csv_fp + " already exists, exiting");

if (File.exists(horizontal_uniformity_results_csv_fp))
	exit(horizontal_uniformity_results_csv_fp + " already exists, exiting");

if (File.exists(vertical_uniformity_results_csv_fp))
	exit(vertical_uniformity_results_csv_fp + " already exists, exiting");

// create directory to store all results
File.makeDirectory(analysis_results_dp);
if (!File.exists(analysis_results_dp))
	exit("Error: unable to create directory " + analysis_results_dp);

// create directory to store the screenshots and csv results files for SNR
File.makeDirectory(snr_results_dp);
if (!File.exists(snr_results_dp))
	exit("Error: unable to create directory " + snr_results_dp);

// create directory to store the screenshots and csv results files for uniformity
File.makeDirectory(uniformity_results_dp);
if (!File.exists(uniformity_results_dp))
	exit("Error: unable to create directory " + uniformity_results_dp);

// open the first image and rename it Image_1
open(im_1_fp);
rename("Image_1");

// open the second image and rename it Image_2
open(im_2_fp);
rename("Image_2");

// calculate the difference between the first and second images and rename it Difference Image
run("Calculator Plus", "i1=Image_1 i2=Image_2 operation=[Subtract: i2 = (i1-i2) x k1 + k2] k1=1 k2=200 create");
rename("Difference_Image");

// select the first image
selectWindow("Image_1");

// generate 5 ROIs used to measure the SNR
x_centre = 128;
y_centre = 128;
roi_width = 20;
roi_height = 20;
roi_offset = 45;
 
// top left ROI
makeRectangle(x_centre - roi_width/2  - roi_offset, y_centre - roi_height/2 - roi_offset, roi_width, roi_height); 
roiManager("Add");

// top right ROI
makeRectangle(x_centre - roi_width/2 + roi_offset, y_centre - roi_height/2 - roi_offset, roi_width, roi_height);
roiManager("Add");

// middle ROI
makeRectangle(x_centre - roi_width/2, y_centre - roi_height/2 , roi_width, roi_height);
roiManager("Add");

// bottom left ROI
makeRectangle(x_centre - roi_width/2 - roi_offset, y_centre - roi_height/2 + roi_offset, roi_width, roi_height);
roiManager("Add");

// bottom right ROI
makeRectangle(x_centre - roi_width/2 + roi_offset,  y_centre - roi_height/2 + roi_offset, roi_width, roi_height);
roiManager("Add");

// combine the 5 rois so the user can move them together if needed
roiManager("Combine");

waitForUser( "Move ROIs so they are centred on the middle of the phantom.\nPress OK when finished");
roiManager("Split");

// delete the 5 original ROIs
roiManager("Select", newArray(0, 1, 2, 3, 4));
roiManager("Delete");

// open a csv file to store the mean signal in each ROI and the standard deviation of the signal in the difference image in each ROI
f_snr_csv = File.open(snr_results_csv_fp);
print(f_snr_csv, "ROI,Signal Mean,Difference Std Dev");

run("Set Measurements...", " mean redirect=None decimal=3");
wait(100);

for (i=0; i<5; i++){
	
	// measure the mean signal in Image_1 from the ith ROI 
	roiManager("Select", i);
	selectWindow("Image_1");
	run("Set Measurements...", " mean redirect=None decimal=3");
	roiManager("Measure");
	mean_tmp = getResult("Mean", 0);
	run("Clear Results");

	// measure the standard deviation of the difference image from the ith ROI 
	selectWindow("Difference_Image");
	run("Set Measurements...", " standard redirect=None decimal=3");
	roiManager("Measure");
	stddev_tmp = getResult("StdDev", 0);
	run("Clear Results");

	// save the results to 3 decimal places in the csv file
	print(f_snr_csv, (i+1) + "," + d2s(mean_tmp,3) + "," + d2s(stddev_tmp,3));
}
File.close(f_snr_csv)

// save the SNR ROIs in a zip file
roiManager("save", snr_rois_fp)

// create montage of images with ROIs overlaid and save a screengrab
selectWindow("Image_1");
roiManager("Show All");
run("Capture Image");
saveAs("PNG", screengrab_im_1_rois_fp);
close("Image_1");

selectWindow("Image_2");
roiManager("Show All");
run("Capture Image");

saveAs("PNG", screengrab_im_2_rois_fp);
close("Image_2");

selectWindow("Difference_Image");
roiManager("Show All");
run("Capture Image");
saveAs("PNG", screengrab_diff_im_rois_fp);
close("Difference_Image");

run("Images to Stack", "use");
run("Make Montage...", "columns=3 rows=1 scale=1 label");
saveAs("PNG", screengrab_snr_images_with_rois_fp);

close("*");
File.delete(screengrab_im_1_rois_fp);
File.delete(screengrab_im_2_rois_fp);
File.delete(screengrab_diff_im_rois_fp);

// re-open the first image and rename it Image_1
open(im_1_fp);
rename("Image_1");

// delete the top-left, top-right, bottom-left and bottom-right SNR ROIs
roiManager("Select", newArray(0, 1, 3, 4));
roiManager("Delete");

// determine the middle of the central ROI in voxels rather than mm units
roiManager("Select", 0);
Image.removeScale;
run("Set Measurements...", " centroid redirect=None decimal=1");
roiManager("Measure");
x_centre_new = getValue("X");
y_centre_new = getValue("Y");

// measure the mean signal middle ROI
run("Clear Results");
run("Set Measurements...", " mean redirect=None decimal=3");
roiManager("Measure");	
central_roi_mean = getResult("Mean", 0);
run("Clear Results");

// generate the horizontal and vertical ROIs used to measure the uniformity

// ROI for horizontal uniformity profile
makeRectangle(x_centre_new - 80,  y_centre_new - 5, 160, 10);
roiManager("Add");

// ROI for vertical uniformity profile
makeRectangle(x_centre_new - 5,  y_centre_new - 80, 10, 160);
roiManager("Add");

// get the horizontal profile
run("Clear Results");
roiManager("Select", 1);
horizontal_profile = getProfile();

// save the horizontal profile to a csv file
f_hor_uni = File.open(horizontal_uniformity_results_csv_fp);
print(f_hor_uni, "Profile Data, Central ROI Mean");
for (i=0; i<horizontal_profile.length; i++)
	print(f_hor_uni, d2s(horizontal_profile[i],3) + "," + d2s(central_roi_mean,3));
File.close(f_hor_uni)

// get the vertical profile
run("Clear Results");
roiManager("Select", 2);
// set alt key down for vertical profile of a rectangular selection
setKeyDown("alt");
vertical_profile = getProfile();

// save the horizontal profile to a csv file
f_vert_uni = File.open(vertical_uniformity_results_csv_fp);
print(f_vert_uni, "Profile Data, Central ROI Mean");
for (i=0; i<vertical_profile.length; i++)
	print(f_vert_uni, d2s(vertical_profile[i],3) + "," + d2s(central_roi_mean,3));
File.close(f_vert_uni)

// save the uniformity ROIs to a zip file
roiManager("save", uniformity_rois_fp);

// save a screenshot of the ROIs overlaid on Image_1
selectWindow("Image_1");
roiManager("Show All");
run("Capture Image");
saveAs("PNG", screengrab_im_1_uniformity_rois_fp);

// close any open images, reset results window etc...
run("Fresh Start");