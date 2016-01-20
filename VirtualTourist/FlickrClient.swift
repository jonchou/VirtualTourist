//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Jonathan Chou on 1/18/16.
//  Copyright © 2016 Jonathan Chou. All rights reserved.
//

import UIKit
import CoreData

let BASE_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.photos.search"
let API_KEY = "5196cb5448befb0611703b847aa9f893"
let EXTRAS = "url_m"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"
let SAFE_SEARCH = "1"
let PER_PAGE = "21"

class FlickrClient {


    


    func searchImagesByLatLon(pin: Pin)
    {
        let methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK,
            "safe_search": SAFE_SEARCH,
            "per_page": PER_PAGE,
            "bbox": createBBox(pin)
        ]
        
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
                        
                        if let photosDictionary = parsedResult["photos"] as? NSDictionary
                        {
                            var totalPhotosVal = 0
                            if let totalPhotos = photosDictionary["total"] as? String {
                                totalPhotosVal = (totalPhotos as NSString).integerValue
                            }
                            if totalPhotosVal > 0 {
                                if let photoArray = photosDictionary["photo"] as? [[String: AnyObject]] {
                                    for photo in photoArray {
                                        _ = Photo(dictionary: photo, pin: pin, context: self.sharedContext)

                                    }
                                    
                                    
                                }
                            }
                        }
                        print(parsedResult)
                    }
                } catch {
                    print(parsingError)
                }
                
                
            }
        }
        
        task.resume()
        
    }
    
    func createBBox(pin: Pin) -> String{
        let minLon = (pin.longitude).doubleValue - 0.5
        let minLat = (pin.latitude).doubleValue - 0.5
        let maxLon = (pin.longitude).doubleValue + 0.5
        let maxLat = (pin.latitude).doubleValue + 0.5
        return "\(minLon), \(minLat), \(maxLon), \(maxLat)"
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
    
    // MARK: - Shared Image Cache
    
    struct Caches {
        static let imageCache = ImageCache()
    }
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()

    
}