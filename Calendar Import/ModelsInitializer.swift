//
//  ModelsInitializer.swift
//  Calendar Import
//
//  Created by Андрей on 14.08.15.
//  Copyright (c) 2015 BMSTU. All rights reserved.
//

import Foundation

/* More a namespace than a class */
public class ModelsInitializer {
    
    private static var fetchedNames = [String : String]() // UID -> Name
    private static var groupUIDs = [String : String]() // GroupName -> UID
    private static var namesAreReady = false
    
    private class func extractNames(uids: NSArray) -> [String] {
        var retArr : [String] = []
        for uid in uids {
            if let uidString = uid as? String {
                if let entityName = fetchedNames[uidString] {
                    retArr.append(entityName)
                }
            }
        }
        return retArr
    }
    
    private class func prepareNames(json : NSDictionary) {
        if let auds = json["aud"] as? NSDictionary {
            ModelsInitializer.prepareSimple(auds)
        }
        if let pubs = json["pub"] as? NSDictionary {
            ModelsInitializer.prepareSimple(pubs)
        }
        if let groups = json["group"] as? NSDictionary {
            ModelsInitializer.prepareSimple(groups, isGroup: true)
        }
        namesAreReady = true
    }
    
    private class func prepareSimple(values: NSDictionary, isGroup : Bool = false) {
        for (number, data) in values {
            if let value = data as? NSDictionary {
                if let uid = value["uid"] as? String {
                    if let name = value["name"] as? String {
                        fetchedNames.updateValue(name, forKey: uid)
                        if (isGroup) {
                            groupUIDs.updateValue(uid, forKey: name)
                        }
                    }
                }
            }
        }
    }
    
    private init() {} // Our 'class' is a namespace - no instantiation, it's 'abstract'
    
    public class func getLessons(forGroupName groupName : String, fromJSON data : NSDictionary) -> [Lesson] {
        var result = [Lesson]()
        
        if !namesAreReady {
            prepareNames(data)
        }
        
        if let groupUID = groupUIDs[groupName] {
            if let items = data["item"] as? NSArray {
                for item in items {
                    if let jsonItem = item as? NSDictionary {
                        let lesson = Lesson(jsonLesson: jsonItem)
                        result.append(lesson)
                    }
                }
            }
        }
        return result
    }
    
    static let extractAuds = ModelsInitializer.extractNames
    static let extractPubs = ModelsInitializer.extractNames
    static let extractGroups = ModelsInitializer.extractNames
}