# Virtual_Tourist
created an app that downloads and stores images from Flickr. 
The app will allow users to drop pins on a map, as if they were stops on a tour.
Users will then be able to download pictures for the location and save locations and pictures both. 

--------------------------------------------------------------------------------------------------------------------------

First screen of application which let user drop pins on a map.

<img width="376" alt="screen shot 2016-05-16 at 10 19 28 am" src="https://cloud.githubusercontent.com/assets/17104174/15292258/3d7ac0de-1b50-11e6-9efa-5fd15284fabe.png">

When user select edit button on right corner, it allows to delete pins by selecting them.

<img width="376" alt="screen shot 2016-05-16 at 10 19 38 am" src="https://cloud.githubusercontent.com/assets/17104174/15292260/3f2db1d4-1b50-11e6-816a-f4db89d0f625.png">

When user select one of the dropped pin, it takes user to detail view controller which downloads images from Flikr API ( if location is selected for first time).
If location has been selected by user before than it downloads images from coredata.

<img width="375" alt="screen shot 2016-05-16 at 10 19 49 am" src="https://cloud.githubusercontent.com/assets/17104174/15292263/41a8c444-1b50-11e6-82d6-4511d0395879.png">

After downloading all images, it allows user to select images and remove them by pressing remove button.
Remove buttom will be available only after user selects any image.
Here, user can also update images with new collection button. It will download 10 more images from Flickr API.
When user come back with application , it will show his dropped pins on map and images related to that pin.

<img width="376" alt="screen shot 2016-05-16 at 10 20 07 am" src="https://cloud.githubusercontent.com/assets/17104174/15292265/438cfc76-1b50-11e6-82c3-f5c14447bc22.png">

