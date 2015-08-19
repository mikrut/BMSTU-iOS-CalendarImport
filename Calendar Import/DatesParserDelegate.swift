//
//  DatesParserDelegate.swift
//  Calendar Import
//
//  Created by Андрей on 15.08.15.
//  Copyright (c) 2015 BMSTU. All rights reserved.
//

import Foundation

public class DatesParserDelegate : NSObject, NSXMLParserDelegate {
    var isInsideRightYear : Bool = false
    var neededLearningYear, neededSemester : Int
    var semesterBegin, semesterEnd : NSDate?
    
    init(learningYear : Int, semester : Int) {
        neededLearningYear = learningYear
        neededSemester = semester
    }
    
    public func parser(parser: NSXMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [NSObject : AnyObject]) {
            
            switch elementName {
            case "year": dispatchYear(attributeDict)
            case "date": dispatchDate(attributeDict)
            default: break;
            }
    }
    
    func dispatchYear(attributeDict: [NSObject : AnyObject]) {
        let year = (attributeDict["year"] as? String)!.toInt()!
        isInsideRightYear = year == neededLearningYear
    }
    
    func dispatchDate(attributeDict: [NSObject : AnyObject]) {
        if (isInsideRightYear) {
            let semester = (attributeDict["semester"] as? String)!.toInt()!
            let weeks    = (attributeDict["weeks"] as? String)!.toInt()!
            
            if (semester == neededSemester && weeks == 17) {
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                semesterBegin = dateFormatter.dateFromString((attributeDict["theory_begin"] as? String)!)
                semesterEnd   = dateFormatter.dateFromString((attributeDict["theory_end"] as? String)!)
            }
        }
    }
}