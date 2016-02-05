//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Jonathan Chou on 1/18/16.
//  Copyright © 2016 Jonathan Chou. All rights reserved.
//

import UIKit
import CoreData


class FlickrClient {
    
    var session: NSURLSession
    
    init() {
        session = NSURLSession.sharedSession()
    }

    // searches for photos by Pin location and initializes photo instances into the context
    func searchImagesByLatLon(pin: Pin, pageNum: String)
    {
        let methodArguments = [
            "api_key": Constants.API_KEY,
            "method": Methods.PHOTO_SEARCH,
            "extras": Constants.EXTRAS,
            "format": Constants.DATA_FORMAT,
            "nojsoncallback": Constants.NO_JSON_CALLBACK,
            "safe_search": Constants.SAFE_SEARCH,
            "per_page": Constants.PER_PAGE,
            "bbox": createBBox(pin),
            "page": pageNum
        ]
        
        // create NSURLRequest using properly escaped URL
        let urlString = Constants.BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        // Initialize task for getting data
        let task = session.dataTaskWithRequest(request) { (data, response, downloadError) in
            if let error = downloadError {
                print("Could not complete the request \(error)")
            } else {
                let parsingError: NSError? = nil
                do {
                    if let parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary {
                        
                        if let photosDictionary = parsedResult["photos"] as? NSDictionary
                        {
                            // assigns max page number on first task call
                            dispatch_async(dispatch_get_main_queue()) {
                                if pin.maxPages == 0 {
                                    if let maxPageNum = photosDictionary["pages"] as? Int {
                                        pin.maxPages = maxPageNum
                                    }
                                }
                            }
                            
                            var totalPhotosVal = 0
                            if let totalPhotos = photosDictionary["total"] as? String {
                                totalPhotosVal = (totalPhotos as NSString).integerValue
                            }
                            if totalPhotosVal > 0 {
                                if let photoArray = photosDictionary["photo"] as? [[String: AnyObject]] {
                                    dispatch_async(dispatch_get_main_queue()) {
                                    for photo in photoArray {
                                        _ = Photo(dictionary: photo, pin: pin, context: self.sharedContext)
                                    }
                                    CoreDataStackManager.sharedInstance().saveContext()
                                    }
                                }
                            }
                        }
                    }
                } catch {
                    print(parsingError)
                }
            }
        }
        task.resume()
    }
    
    // downloads the image
    func taskForImage(filePath: String, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {
        
        let url = NSURL(string: filePath)!
        let request = NSURLRequest(URL: url)
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
                let newError = FlickrClient.errorForData(data, response: response, error: error)
                completionHandler(imageData: nil, error: newError)
            } else {
                completionHandler(imageData: data, error: nil)
            }
        }
        task.resume()
        return task
    }
    
    func createBBox(pin: Pin) -> String{
        let minLon = (pin.longitude).doubleValue - 0.5
        let minLat = (pin.latitude).doubleValue - 0.5
        let maxLon = (pin.longitude).doubleValue + 0.5
        let maxLat = (pin.latitude).doubleValue + 0.5
        return "\(minLon), \(minLat), \(maxLon), \(maxLat)"
    }
    
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        
        if data == nil {
            return error
        }
        
        do {
            let parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
            
            if let parsedResult = parsedResult as? [String : AnyObject], errorMessage = parsedResult[FlickrClient.Keys.ErrorStatusMessage] as? String {
                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                return NSError(domain: "Flickr Error", code: 1, userInfo: userInfo)
            }
        } catch _ {}
        
        return error
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
    
    // MARK: - Shared Context
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()

    
}