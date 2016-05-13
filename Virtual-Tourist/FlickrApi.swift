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
    func getFlickrData(page: Int,coordinate:CLLocationCoordinate2D, completion:(photoDict: NSArray?,error: String?) -> Void)
    {
        let searchString = "&lat=\(coordinate.latitude)&lon=\(coordinate.longitude)"
        let pageString = "&per_page=\(10)&page=\(page)&format=json&nojsoncallback=1"
        let requestURL = NSURL(string: BaseUrl + method + APIKEY + searchString + pageString)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithURL(requestURL!, completionHandler: { data, response, error -> Void in
            if data == nil && error == nil
            {
                completion(photoDict: nil,error: "Connection Problem")
            }
            else if error != nil
            {
                completion(photoDict: nil,error: "Network Problem")
            }
            else
            {
             //once location is saved, get images of that location
                dispatch_async(dispatch_get_main_queue())
                {
                    self.getImages(coordinate, data: data!, completion: { (photoDict, error) in
                            completion(photoDict: photoDict!,error: error)
                            })
                }
            }
        })
        task.resume()
   }
    func getImages(coordinate:CLLocationCoordinate2D,data: NSData,completion:(photoDict: NSArray? ,error: String?) -> Void)
   {
      do
      {
        let result = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? NSDictionary
        let dict = result!["photos"] as! NSDictionary
        let photodict = dict["photo"] as? NSArray
        if photodict != nil
        {
            completion(photoDict: photodict!, error: "")
        }
        else
        {
            completion(photoDict: photodict!,error: "Data is nil")
        }
    }
    catch
    {
        completion(photoDict: nil, error: "Json Error")
    }
    }
}