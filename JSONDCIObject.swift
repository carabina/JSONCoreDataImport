//
//  JSONDCIObject.swift
//
//  Created by Barbier Joey on 10/12/2015.
//

import UIKit
import CoreData

class JSONDCIEnvironment{
    var currentFetchEntity: NSFetchRequest<NSFetchRequestResult>?
    var currentDescriptionEntity = NSEntityDescription()
}

class JSONDCIEntity: NSObject{
    var name = String()
    var numberData = 0
}
