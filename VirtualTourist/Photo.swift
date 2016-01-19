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
   // @NSManaged var pin: Pin
 //   @NSManaged var longitude: NSNumber
    @NSManaged var id: String?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String:AnyObject], pin: Pin, context: NSManagedObjectContext){
        
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        //self.pin = pin
    }

}