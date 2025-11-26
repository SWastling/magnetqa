// close any open images, reset results window etc...
run("Fresh Start");

// open a dialog box for the user to enter directory paths and specify the slice and RF coil information
path = getDirectory("home")
Dialog.create("EPI Stability Test Details");
Dialog.addDirectory("Directory containing DICOM images:", path);
Dialog.addDirectory("Results directory:", path);
Dialog.addRadioButtonGroup("Slice orientation:", newArray("TRA", "COR", "SAG"), 1, 3, "TRA");
Dialog.addRadioButtonGroup("RF coil:", newArray("BC", "HC"), 1, 2, "BC");
Dialog.show();
im_dp = Dialog.getString();
output_dp = Dialog.getString();
slice_orientation = Dialog.getRadioButton;
rf_coil = Dialog.getRadioButton;

// create a directory to store the screenshots and csv results files
results_dp = output_dp + File.separator + "Analysis Results";
File.makeDirectory(results_dp);

// open the set of DICOM files (images 21-120) in im_dp and rename them im
File.openSequence(im_dp, " start=21");
rename("im");

// zoom the image to 400%
run("Set... ", "zoom=400 x=32 y=32");

// create a central ROI
makeRectangle(25, 25, 15, 15); 
roiManager("Add");

roiManager("select", 0);
waitForUser( "Move ROIs so they are centred on the middle of the phantom.\nPress OK when finished");
roiManager("Update");
wait(100);

run("Set Measurements...", " mean redirect=None decimal=3");
roiManager("Multi Measure");
wait(100);

csv_fp = results_dp + File.separator + rf_coil + "_" + slice_orientation + "_EPI_STABILITY.csv";
saveAs("Results", csv_fp);

// save the uniformity ROIs to a zip file
rois_fp = results_dp + File.separator + rf_coil + "_" + slice_orientation + "_EPI_STABILITY_ROI.zip";
roiManager("save", rois_fp);

// save a screenshot of the ROIs overlaid on Image_1
selectWindow("im");
roiManager("Show All");
run("Capture Image");
screengrab_roi_fp = results_dp + File.separator + rf_coil + "_" + slice_orientation + "_EPI_STABILITY_ROI.png";
saveAs("PNG", screengrab_roi_fp);

// close any open images, reset results window etc...
run("Fresh Start");