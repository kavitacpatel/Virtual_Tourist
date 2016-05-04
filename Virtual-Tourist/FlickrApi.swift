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
    
    func getFlickrImage(completion:(err: String)-> Void)
    {
            let photoURL = "https://farm\(self.farmId).staticflickr.com/\(self.serverId)/\(self.photoId)_\(self.secret)_\(self.size).jpg"
            if let url = NSURL(string: photoURL)
            {
                // Download Image
                if let data = NSData(contentsOfURL: url)
                {
                    let img = UIImage(data: data)
                    //Save Photos to CoreData
                    FlickrPhotos.sharedInstance.saveImages(img!, completion: { (error) in
                        if error != ""
                        {
                            completion(err: error)
                        }
                    })
                }
                else
                {
                    completion(err: "Error in Loading Photos")
                }
            }
        else
            {
                completion(err: "Error in URL")
            }
    }
    func getFlickrData(page: Int,coordinate: CLLocationCoordinate2D, completion:(error: String?) -> Void)
    {
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
              do
              {
                let result = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? NSDictionary
                let dict = result!["photos"] as! NSDictionary
                let photodict = dict["photo"] as? NSArray
                if photodict != nil
                {
                    // remove Photos From CoreData
                    FlickrPhotos.sharedInstance.removeImages({ (error) in
                        if error != ""
                        {
                            completion(error: error)
                        }
                    })
                    for photo in photodict!
                    {
                        self.farmId = photo.valueForKey("farm") as! NSNumber
                        self.serverId = photo.valueForKey("server") as! String
                        self.photoId = photo.valueForKey("id") as! String
                        self.secret = photo.valueForKey("secret") as! String
                        //get Image
                        self.getFlickrImage({ (err) in
                            if err != ""
                            {
                                completion(error: "Can not get Images")
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
                completion(error: "Json Serialization Problem")
            }
            }
        })
        task.resume()
   }
}