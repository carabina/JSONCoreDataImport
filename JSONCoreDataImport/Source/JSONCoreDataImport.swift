//
//  JSONDataContextImport.swift
//
//  Created by Barbier Joey on 30/11/2015.
//

import UIKit
import CoreData
import SwiftyJSON
import Alamofire

protocol JSONCoreDataImportDelegate: class{
    func JSONCoreDataImportError(_ error: Int)
}

class JSONCoreDataImport{
    
    var managedObjectContext: NSManagedObjectContext

    let jsonDCIEntity = JSONDCIEntity()
    let jsonDCIEnvironment = JSONDCIEnvironment()
    
    var delegate :JSONCoreDataImportDelegate?
    
    let pathsDoc: URL
    
    var currentEntityName : String?
    
    init(delegate:JSONCoreDataImportDelegate,managedObjectContext: NSManagedObjectContext, pathsDoc: URL){
        self.delegate = delegate
        self.managedObjectContext = managedObjectContext
        self.pathsDoc = pathsDoc
    }
    
    /*
    * Import JSON
    *   import JSON with key = entity name.
    *   - dataJSON : JSON qui comporte les données à importer
    *   - groupList : afin de savoir quand les images sont DL
    *   - withImage : JSON comportant des images à télécharger ? 
    *   - imageColumnName : Nom de la colonne des images dans le json
    *   - urlCDNImage : dans le cas de l'utilisation d'un CDN
    */
    func importJSON(_ dataJSON : JSON,groupList: DispatchGroup? = nil, withImage: Bool = false, imageColumnName:String? = nil, urlCDNImage: String? = nil){
        for (entityName, entityData) in dataJSON{
            if checkEntityExist(entityName){
                
                jsonDCIEntity.name = entityName
                jsonDCIEntity.numberData = entityData.count
                
                //truncate entity :
                self.truncateEntity(by: entityName)

                self.currentEntityName = entityName
                //import data :
                self.importDataEntity(entityData,groupList:groupList, withImage: withImage, imageColumnName:imageColumnName, urlCDNImage: urlCDNImage)
                
            }else{
                fatalError("JSONDataContextImport : importJSON()|Entity '\(entityName)' not fount ! :'( " )
            }
        }
    }
    
    fileprivate func importDataEntity(_ data: JSON,groupList: DispatchGroup? = nil, withImage: Bool = false, imageColumnName:String? = nil, urlCDNImage: String? = nil){
        
        // Boucle pour la récupération de chaque ligne :
        for ( _ , value ) in data{
            
            let entity = NSManagedObject(entity: jsonDCIEnvironment.currentDescriptionEntity, insertInto: self.managedObjectContext)
            
            // Boucle pour la récupération de chaque colonne :
            for (entityKey, entityVal) in value{
                
                if  checkKeyNameExist(entityKey)
                {
                    entity.setValue(entityVal.rawValue, forKey: entityKey)
                    if(withImage && imageColumnName == entityKey){
                        //dans le cas d'un téléchargement d'image +1 dans le group
                        if let groupList = groupList{
                            groupList.enter()
                        }
                        
                        let destination : DownloadRequest.DownloadFileDestination = { (temporaryURL, response) in
                        
                            if let groupList = groupList{
                                groupList.leave()
                            }
                            
                            let documentsDirectory = self.pathsDoc
                            let dataPath = documentsDirectory.appendingPathComponent("/\(self.currentEntityName!.lowercased())")
                            
                            do {
                                if !FileManager.default.fileExists(atPath: dataPath.path){
                                    try FileManager.default.createDirectory(atPath: dataPath.path, withIntermediateDirectories: false, attributes: nil)
                                }
                            } catch let error as NSError {
                                NSLog(error.localizedDescription);
                            }
                            do {
                                try (self.pathsDoc as NSURL).setResourceValue(NSNumber(value: true), forKey: URLResourceKey.isExcludedFromBackupKey)
                            } catch {
                                print("failed to set resource value (excluded)")
                            }
                            
                            let filePath = self.pathsDoc.appendingPathComponent("\(self.currentEntityName!.lowercased())/\(entityVal.rawValue)")
                            
                            if FileManager.default.fileExists(atPath: "\(dataPath)/\(entityVal.rawValue)") {
                                do {
                                    try FileManager.default.removeItem(atPath: "\(dataPath)/\(entityVal.rawValue)")
                                }catch _ {
                                    NSLog("delete error")
                                }
                            }
                            
                            return (filePath, [DownloadRequest.DownloadOptions.createIntermediateDirectories, DownloadRequest.DownloadOptions.removePreviousFile])
                        }
                        
                        
                        Alamofire.download("\(urlCDNImage!)\(currentEntityName!.lowercased())/\(entityVal.rawValue)", to: destination).responseJSON{ response in
                            
                            guard case let .failure(error) = response.result else { return }
                            
                            if let error = error as? AFError, response.response?.statusCode != 200{
                                NSLog("REQUEST: \(request)")
                                NSLog("RESPONSE: \(error)")
                                
                                guard let errorCode = error.responseCode else{
                                    return self.delegate!.JSONCoreDataImportError(0)
                                }
                                
                                self.delegate!.JSONCoreDataImportError(errorCode)
                            }
                        }
                    }
                }else{
                    NSLog("When import data for entity : '\(jsonDCIEntity.name)' this key : '\(entityKey)' not found ! \(entityVal))")
                }
            }
            
            do {
                try self.managedObjectContext.save()
            } catch let error as NSError  {
                NSLog("Could not save \(error), \(error.userInfo)")
            }
        }
    }
}

//action Core Data
extension JSONCoreDataImport{

    func truncateEntity(by name: String)
    {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: name)
        fetchRequest.returnsObjectsAsFaults = false
        
        do
        {
            let results = try self.managedObjectContext.fetch(fetchRequest)
            for managedObject in results
            {
                let managedObjectData:NSManagedObject = managedObject
                self.managedObjectContext.delete(managedObjectData)
            }
        } catch let error as NSError {
            print("Detele all data in \(name) error : \(error) \(error.userInfo)")
        }
    }
    
}


//Check Data :
extension JSONCoreDataImport{
    
    ///Check :
    fileprivate func checkKeyNameExist(_ receiptKey : String) -> Bool{
        
        let keyList = jsonDCIEnvironment.currentDescriptionEntity.attributesByName
        for (key,_) in keyList{
            
            if receiptKey == key{
                return true;
            }
        }
        
        return false
    }
    ///check if entity exist
    fileprivate func checkEntityExist(_ entityKey:String) -> Bool{
        if let checkEntity = NSEntityDescription.entity(forEntityName: entityKey, in: self.managedObjectContext){
            
            //recup name of entity :
            jsonDCIEntity.name = entityKey
            
            //set environment variable :
            jsonDCIEnvironment.currentFetchEntity = NSFetchRequest(entityName: entityKey)
            jsonDCIEnvironment.currentDescriptionEntity = checkEntity
            
            return true
        }else{
            return false
        }
    }
}
