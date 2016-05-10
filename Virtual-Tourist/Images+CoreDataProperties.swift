//
//  Images+CoreDataProperties.swift
//  Virtual-Tourist
//
//  Created by kavita patel on 5/6/16.
//  Copyright © 2016 kavita patel. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Images {

    @NSManaged var imagesId: NSString?
    @NSManaged var pin: Pin?

}
