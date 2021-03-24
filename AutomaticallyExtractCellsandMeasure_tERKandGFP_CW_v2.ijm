// Caroline Wee Mar 24 2021
// To extract GFP-positive cells
// First, open an image and crop/make substacks to satisfaction.
// Use CropandSubstack_manualCW_v1.ijm
// Then, SAVE ALL CROPPED IMAGES TO A SEPARATE FOLDER
// Need to download latest FIJI version for Z-information to be accurate
// Do not click on images during analysis (if not in batch mode)!

// PARAMETERS THAT NEED TO BE SET
ovalsize = 10; // sets number of pixels of circle diameter - need to change) Usually 10
GFPchannel = 1;// need to change depending on image
pERKchannel = 2;
tERKchannel = 3;   
substack = 1; // yes = 1 -- basically whether there is GFP fluorescence in every image 
poortERK = 0; //if tERK quality is poor, additional processing will be implemented
BatchMode = false;
minsize_tERK = 1; //microns^2
maxsize_tERK = 50; //microns^2
minsize_GFP = 1; //microns^2
maxsize_GFP = 100; //microns^2

setBatchMode(BatchMode); // true unless for demo purposes

source_dir = getDirectory("Source Directory");
target_dir = getDirectory("Source Directory");

list = getFileList(source_dir);
list = Array.sort(list);

for (j=0; j<list.length; j++) {
    Image = source_dir + list[j];
    open(Image);
    name = getTitle();
    rename("Image");

	// Start of analysis
    run("Clear Results");

    // This is to make a duplicate image that can then be stored for future use, while the tERK channel is processed for cell segmentation

    run("Duplicate...", "duplicate");
    rename("Imagefull");
    run("Duplicate...", "duplicate");
    rename("Imagefull2");
    selectWindow("Image");

    // Processing of tERK channel *need to close other two if not C3*
    run("Split Channels");

    // close pERK channel.
    close("C" + pERKchannel + "-Image");

    // Analysis of tERK
    selectWindow("C" + tERKchannel + "-Image");

    // Image processing for cell segmentation. These could be tweaked.
    run("Invert LUT");
    run("Subtract Background...", "rolling = 100 stack");
    run("Smooth", "stack");
    run("Gaussian Blur...", "sigma=2 stack");
    run("Enhance Contrast", "staurated=0.4");

    // Finding maxima for entire stack
    selectWindow("C" + tERKchannel + "-Image");
    input = getImageID();
     n = nSlices();
     k = 1;
        
    for (i=1; i<=n; i+=k) {
        showProgress(i, n);
        selectImage(input);
        setSlice(i);
        run("Find Maxima...", "noise=5 output=[Maxima Within Tolerance] exclude");
            
        if (i==1) 
            output = getImageID();
        else {
            run("Select All");
            run("Copy");
            close();
            selectImage(output);
            run("Add Slice");
            run("Paste");
         }
    }
  	
    run("Select None");

    // Run Analyze Particles to only extract particles of certain size and circularity (set below). I
    selectWindow("C" + tERKchannel + "-Image(1) Maxima");

    // Additional processing if tERK staining is poor
    if (poortERK ==1){
        run("Open", "stack");
        run("Erode", "stack");
        run("Watershed", "stack");
    }

	// this is customizable
    //run("Analyze Particles...", "size=1-20 pixel circularity = 0.05-1.00 show=Outlines display stack"); 
    run("Analyze Particles...", "size=" + minsize_tERK + "-" + maxsize_tERK + " circularity = 0.05-1.00 show=Outlines display stack"); 
    //size here pixels - might need to change

    // Now to measure intensities of all extracted particles
    selectWindow("Imagefull");
    run("Set Measurements...", "mean center stack nan redirect=None decimal=3");

    npoints = nResults;
    xvalue = newArray(npoints);
    yvalue = newArray(npoints);
    zvalue = newArray(npoints);

    // to get the x y z coordinates for all points selected
 
    for (i=0; i<npoints; i+=k) {
        x = getResult("XM",i);
        y = getResult("YM", i);
        z = getResult("Slice", i);
        xvalue[i]= x;
        yvalue[i]= y;
        zvalue[i] = z;
	}

    run("Clear Results"); //now is when I make the actual measurements 
    run("Input/Output...", "jpeg=85 gif=-1 file =.xls");

    // to draw ovals over each point, and measure the intensity values
    for (i=0; i<npoints; i+=k) {
    	Stack.setChannel(1);
    	Stack.setSlice(zvalue[i]) 
    	toUnscaled(xvalue[i], yvalue[i]);
    	makeOval(xvalue[i]-ovalsize/2, yvalue[i]-ovalsize/2, ovalsize, ovalsize);
    	run("Measure");
    	fill();
    	setColor(0);

        // Measure pERK and tERK values
		Stack.setChannel(pERKchannel)
        run("Measure");
        Stack.setChannel(tERKchannel)
        run("Measure");
        fill();
        run("Select None");
        Stack.setChannel(1);
	}

	saveAs("Results",  target_dir + '/' + name + "-allcells.xls");

	//To close open windows 
	run("Clear Results"); 
	if (BatchMode == false){
	selectWindow("C" + tERKchannel + "-Image(1) Maxima");
	run("Close");
	selectWindow("Drawing of " + "C" + tERKchannel + "-Image(1) Maxima");
	run("Close");
	selectWindow("Imagefull");
	run("Close");
	selectWindow("C" + tERKchannel + "-Image");
	run("Close");
	}

	//now for extracting cells using GFP channel

	//Image processing for cell segmentation
	selectWindow("C" + GFPchannel + "-Image");
	run("8-bit");
	
	if (substack==1) {
	run("Make Binary", "method=Intermodes background=Default black calculate");
	} else {
	run("Make Binary", "method=Intermodes background=Default black");	
	}

	run("Open", "stack");
	
	run("Erode", "stack");
	run("Watershed", "stack");
    //run("Analyze Particles...", "size=1-100 circularity = 0.02-1.00 show=Outlines display stack"); //size here is in microns
	run("Analyze Particles...", "size=" + minsize_GFP + "-" + maxsize_GFP + " circularity = 0.02-1.00 show=Outlines display stack"); 

    // Now to measure intensities of all extracted particles
    selectWindow("Imagefull2");

    npoints = nResults;
    xvalue = newArray(npoints);
    yvalue = newArray(npoints);
    zvalue = newArray(npoints);

    // to get the x y z coordinates for all points selected
    for (i=0; i<npoints; i+=k) {
        x = getResult("XM",i);
        y = getResult("YM", i);
        z = getResult("Slice", i);
        xvalue[i]= x;
        yvalue[i]= y;
        zvalue[i] = z;
    }

    run("Clear Results"); // now is when I make the actual measurements 
    run("Input/Output...", "jpeg=85 gif=-1 file =.xls");

    // to draw ovals over each point, and measure the intensity values

    for (i=0; i<npoints; i+=k) {
		Stack.setChannel(GFPchannel); //GFP channel first
		Stack.setSlice(zvalue[i]) 
		toUnscaled(xvalue[i], yvalue[i]);
		makeOval(xvalue[i]-ovalsize/2, yvalue[i]-ovalsize/2, ovalsize, ovalsize);
		run("Measure");
		fill();
		setColor(0);

        // Measure pERK and tERK values
		Stack.setChannel(pERKchannel)
        run("Measure");
        Stack.setChannel(tERKchannel)
        run("Measure");
        fill();
        run("Select None");
        Stack.setChannel(1);
    }

    run("Close All");
    saveAs("Results",  target_dir + '/' + name + "-GFP.xls");
}

setBatchMode(false);
