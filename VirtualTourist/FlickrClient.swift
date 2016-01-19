//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Jonathan Chou on 1/18/16.
//  Copyright © 2016 Jonathan Chou. All rights reserved.
//

import UIKit

let BASE_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.photos.search"
let API_KEY = "5196cb5448befb0611703b847aa9f893"
let GALLERY_ID = "5704-72157622566655097"
let EXTRAS = "url_m"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"

class FlickrClient {
    
    
    let methodArguments = [
        "method": METHOD_NAME,
        "api_key": API_KEY,
        "text": "baby asian elephant",
        "extras": EXTRAS,
        "format": DATA_FORMAT,
        "nojsoncallback": NO_JSON_CALLBACK
    ]

    


    func getImageFromFlickrBySearch(methodArguments: [String: AnyObject])
    {
        // Get the shared NSURLSession to facilitate network activity
        let session = NSURLSession.sharedSession()
        
        // Create NSURLRequest using properly escaped URL
        let urlString = BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        
        /* 4 - Initialize task for getting data */
        let task = session.dataTaskWithRequest(request) { (data, response, downloadError) in
            if let error = downloadError {
                print("Could not complete the request \(error)")
            } else {
                let parsingError: NSError? = nil
                do {
                    if let parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary {
                        
                        // if let photosDictionary = p
                        
                        if let photosDictionary = parsedResult["photos"] as? NSDictionary
                        {
                            var totalPhotosVal = 0
                            if let totalPhotos = photosDictionary["total"] as? String {
                                totalPhotosVal = (totalPhotos as NSString).integerValue
                            }
                            if totalPhotosVal > 0 {
                                if let photoArray = photosDictionary["photo"] as? [[String: AnyObject]] {
                                    let randomPhotoIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
                                    let photoDictionary = photoArray[randomPhotoIndex] as [String: AnyObject]
                                    let photoTitle = photoDictionary["title"] as? String /* non-fatal */
                                    
                                    let imageUrlString = photoDictionary["url_m"] as? String
                                    print(imageUrlString)
                                    
                                }
                            }
                        }
                        //   print(parsedResult)
                    }
                } catch {
                    print(parsingError)
                }
                
                
            }
        }
        
        task.resume()
        
    }
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }

    
}