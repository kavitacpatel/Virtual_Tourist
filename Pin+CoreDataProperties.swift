//
//  Pin+CoreDataProperties.swift
//  Virtual-Tourist
//
//  Created by kavita patel on 5/4/16.
//  Copyright © 2016 kavita patel. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Pin {

    @NSManaged var latitude: NSNumber?
    @NSManaged var latitudeDelta: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var longitudeDelta: NSNumber?

}
