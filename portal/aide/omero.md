---
layout: default
---

## OMERO server

<img src="/images/omero-logo-200.png">


OMERO handles all your images in a secure central repository. You can backup, view, organize, analyze and share your data from anywhere you have internet access. Work with your images from a desktop app (Windows, Mac or Linux), from the web or from 3rd party software. Over 130 image file formats supported, including all major microscope formats.

[Official website here](http://www.openmicroscopy.org/site/products/omero)

You can use [OMERO.web](http://omero.ccs.usherbrooke.ca/) or the [OMERO.insight](http://downloads.openmicroscopy.org/latest/omero5) client to view, organize and share your data. If you need help with OMERO server or if you want an account, contact Daniel.Garneau[at]Usherbrooke.ca


### OMERO Guidelines:

1. <b>OMERO.insight installation (Windows, Mac, Linux):</b>  
    * Download the OMERO client on the [OMERO website](http://www.openmicroscopy.org/site/products/omero/downloads).
    * Follow the instructions for installation [here](http://help.openmicroscopy.org/getting-started-5.html).
    * The server address is "omero.ccs.usherbrooke.ca" (You will need this to install OMERO.client).


2. <b>Changing your password using [OMERO.web](http://omero.ccs.usherbrooke.ca/):</b>  
    * Click on your name at the top right of the screen.  
    * Select "User Settings".  
    * Click on the button "Change Password" at the bottom of the page.  
    <img src="/images/omero_change_password.png">

3. <b>Download images from OMERO server:</b>  
   
    <b>With OMERO.web client</b>  
        * Select an image.  
        * Click on the arrow at the top of the right panel.  
        * To download many images at the same time, use OMERO.insight (see below)  
        <img src="/images/omero_download_omeroweb_0.png">     
    <b>With OMERO.insight client</b>  
        * Select the image you want to download (multiple images can be selected).  
        * Click on the red arrow at the top of the right panel.  
        * Select "Download..." if you want to download the original files.  
        * Select "Save as..." if you want to download the images as jpeg, png or tiff.  
        <img src="/images/omero_download_insight.png">    
    
4. <b>Upload images to OMERO server</b>  
    <b> ***You need OMERO.insight client to upload images on the server. [Installation instruction here.](http://bioinfo.ccs.usherbrooke.ca/drupal/node/188)***</b>    
    * Open the Importer by clicking on the blue arrow with three dots.   
    <img src="/images/omero_insight_open.png">   
    * In the "Import Data" dialog :
        * On the left panel, browser to the location where your images are located.
        * Select the image files or folders you want to import.
        * Click on the blue arrow in the middle of the page to select the files/folders.
        * Select the Project or create a new one (Projects are the main folders).
        * Select the Dataset or create a new one (Datasets are the sub-folders).
        * Click "Add to the Queue".
        * You will see the folders/files to upload in the right panel.
        * Click "Import" and your images will be imported to the OMERO server.
        * You can close the "Import Data" window when all images are transfered.
    * Make sure to click "Refresh the tree" if you want to see the new images.
    * More informations [here](http://help.openmicroscopy.org/importing-data-5.html).

5. <b>View images from other users</b>  

    <b>With OMERO.web client</b>  
        * Click on the group/username at top left of the screen.
        * Select the desired group and user.
        <img src="/images/omero_view_other_users.png">     
    <b>With OMERO.insight client</b>  
        * Click on "Dislpay Groups" at the top of the window.  
        * Select the desired group and user (multiple groups and users can be selected).  
        <img src="/images/omero_view_other_users_insight.png">   
