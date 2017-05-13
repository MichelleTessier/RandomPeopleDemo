//
//  PeopleCoreDataService.swift
//  VivintSolarDemo
//
//  Created by Michelle Tessier on 5/12/17.
//  Copyright © 2017 Michelle Tessier. All rights reserved.
//

import Foundation
import CoreData

class PeopleCoreDataService: NSObject {

    class func createPersonFromWebPerson(_ webPerson : WebPerson, context : NSManagedObjectContext, completion : @escaping ((Person?) -> ())) {
        
        context.perform {
            
            guard let person = NSEntityDescription.insertNewObject(forEntityName: "Person", into: context) as? Person,
            let thumbnail = NSEntityDescription.insertNewObject(forEntityName: "Thumbnail", into: context) as? Thumbnail else { completion(nil); return }
            
            person.name = webPerson.name
            person.email = webPerson.email
            person.phone = webPerson.phone
            person.identifier = webPerson.id
            thumbnail.remoteURL = webPerson.thumbnailURL
            person.thumbnail = thumbnail
            
            completion(person)
            
        }
    
    }
  
}

//I would normally make this a different class, just putting these two together to make them easier to read

class VivintSolarDemoDataModel: NSObject {
    
    static let sharedModel = VivintSolarDemoDataModel()
    let mainContext : NSManagedObjectContext
    let modelName = "VivintSolarDemoModel"
    
    override init() {
        
        guard let modelURL = Bundle.main.url(forResource: modelName , withExtension:"momd") else {
            fatalError("Error loading model from bundle")
        }
        
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }
        
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        
        mainContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        mainContext.persistentStoreCoordinator = psc
        
        guard let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
            fatalError("Unable to resolve document directory")
        }
        let storeURLName = modelName + ".sqlite"
        let storeURL = docURL.appendingPathComponent(storeURLName)
        do {
            try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
            super.init()
            
        } catch {
            fatalError("Error migrating store: \(error)")
        }
        
        
    }
    
}
