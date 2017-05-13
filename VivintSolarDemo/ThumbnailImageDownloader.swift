//
//  ThumbnailImageDownloader.swift
//  VivintSolarDemo
//
//  Created by Michelle Tessier on 5/12/17.
//  Copyright © 2017 Michelle Tessier. All rights reserved.
//

import Foundation
import CoreData
import UIKit


class ThumbnailImageDownloader: NSObject {

    
    class func dowloadThumbnailImageForThumnail(thumbnail : Thumbnail, completion : @escaping ((UIImage?, NSManagedObjectID) -> ())) {
        
        let thumbnailID = thumbnail.objectID
        guard let remoteURLString = thumbnail.remoteURL, let url = URL(string: remoteURLString) else { completion(nil, thumbnailID); return }
        
        let task = PeopleWebService.dataTaskWithURL(url) { (data, error) in
            
            guard let data = data, error == nil else {
                completion(nil, thumbnailID)
                return
            }
            
            thumbnail.managedObjectContext?.perform {
                thumbnail.imageData = data as NSData
            }
            
            completion(UIImage(data: data), thumbnailID)
       
        }
        
        task.resume()
        
    }
    
}
