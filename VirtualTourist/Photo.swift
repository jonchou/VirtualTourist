//
//  Photo.swift
//  VirtualTourist
//
//  Created by Jonathan Chou on 1/18/16.
//  Copyright © 2016 Jonathan Chou. All rights reserved.
//

import CoreData
import UIKit


class Photo: NSManagedObject {
    struct Keys {
        static let ID = "id"
        static let imageURL = "url_m"
       // static let ReleaseDate = "release_date"
    }
    
    
    @NSManaged var id: String?
    @NSManaged var imagePath: String?
    @NSManaged var pin: Pin
    @NSManaged var imageUrl: String?

    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String:AnyObject], pin: Pin, context: NSManagedObjectContext){
        
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        self.pin = pin
        self.id = dictionary[Keys.ID] as? String
        self.imageUrl = dictionary[Keys.imageURL] as? String
        
        let myURL = NSURL(string: imageUrl!)
        self.imagePath = myURL?.lastPathComponent
    }

    var image: UIImage? {
        
        get {
            return FlickrClient.Caches.imageCache.imageWithIdentifier(imagePath)
        }
        
        set {
            FlickrClient.Caches.imageCache.storeImage(image, withIdentifier: imagePath!)
        }
    }
}