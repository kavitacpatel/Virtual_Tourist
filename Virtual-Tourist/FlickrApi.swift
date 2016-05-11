//
//  FlickerApi.swift
//  Virtual-Tourist
//
//  Created by kavita patel on 5/1/16.
//  Copyright © 2016 kavita patel. All rights reserved.
//

import Foundation
import MapKit

class FlickrApi: AnyObject
{
    var farmId: NSNumber = 0.0
    var serverId: String = ""
    var photoId: String = ""
    var secret: String = ""
    let size = "z"
    
    
    func getFlickrImage(coordinate: CLLocationCoordinate2D,imgName: String,completion:(err: String)-> Void)
    {
            let photoURL = "https://farm\(self.farmId).staticflickr.com/\(self.serverId)/\(self.photoId)_\(self.secret)_\(self.size).jpg"
            if let url = NSURL(string: photoURL)
            {
                // Download Image
                if let data = NSData(contentsOfURL: url)
                {
                //Save Photos to CoreData
                   
                        let img = UIImage(data: data)
                        Images.imagesInstance.saveImages(coordinate.latitude,long: coordinate.longitude, img: img!, imgName: self.photoId)
                    dispatch_async(dispatch_get_main_queue())
                    {
                        completion(err: "")
                    }
                 }
                else
                {
                    dispatch_async(dispatch_get_main_queue())
                    {
                        completion(err: "Error in Loading Photos")
                    }
                }
            }
            else
            {
                dispatch_async(dispatch_get_main_queue())
                {
                    completion(err:"Error in URL")
                }
            }
    }
    func getFlickrData(page: Int,coordinate:CLLocationCoordinate2D,span: MKCoordinateSpan?, completion:(error: String?) -> Void)
    {
        print(page)
        let searchString = "&lat=\(coordinate.latitude)&lon=\(coordinate.longitude)"
        let pageString = "&per_page=\(10)&page=\(page)&format=json&nojsoncallback=1"
        let requestURL = NSURL(string: BaseUrl + method + APIKEY + searchString + pageString)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithURL(requestURL!, completionHandler: { data, response, error -> Void in
            if data == nil && error == nil
            {
                completion(error: "Connection Problem")
            }
            else if error != nil
            {
                completion(error: "Network Problem")
            }
            else
            {
               //save location- it will check if location already saved than it wont save it again
                Pin.pinInstance.saveLocation(coordinate, span: span, completion: { (error) in
                    if error != ""
                    {
                        completion(error: error)
                    }
                })
                  //once location is saved, get images of that location 
                        self.getImages(coordinate,data: data!, completion:
                            { (error) in
                                    completion(error: error)
                            })
            }
        })
        task.resume()
   }
  func getImages(coordinate:CLLocationCoordinate2D,data: NSData,completion:(error: String?) -> Void)
   {
    do
    {
        let result = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? NSDictionary
        let dict = result!["photos"] as! NSDictionary
        let photodict = dict["photo"] as? NSArray
        if photodict != nil
        {
            for photo in photodict!
            {
                self.farmId = photo.valueForKey("farm") as! NSNumber
                self.serverId = photo.valueForKey("server") as! String
                self.photoId = photo.valueForKey("id") as! String
                self.secret = photo.valueForKey("secret") as! String
                
                //Get Flickr Images
                
                 self.getFlickrImage(coordinate,imgName:self.photoId , completion: { (err) in
                    dispatch_async(dispatch_get_main_queue())
                    {
                        if err != ""
                        {
                            completion(error: "Can not get Images")
                        }
                    }
                    })
            }
            completion(error: "")
        }
        else
        {
            completion(error: "Data is nil")
        }
        
    }
    catch
    {
        completion(error: "Json serialize error")
    }

    }
}