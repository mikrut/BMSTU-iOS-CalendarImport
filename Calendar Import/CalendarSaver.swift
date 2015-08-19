//
//  CalendarSaver.swift
//  Calendar Import
//
//  Created by Андрей on 15.08.15.
//  Copyright (c) 2015 BMSTU. All rights reserved.
//

import Foundation
import EventKit

public class CalendarSaver {
    public class func importGroup(groupName : String) {
        let date = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(.CalendarUnitYear | .CalendarUnitMonth, fromDate: date)
        let semester     = components.month > 6 ? 1 : 2
        let learningYear = components.year - semester / 2
        
        
        if let datesPath = NSBundle.mainBundle().pathForResource("dates", ofType: "xml") {
            if let dates = NSInputStream(fileAtPath: datesPath) {
                let xmlParser : NSXMLParser = NSXMLParser(stream: dates)
                let parserDelegate = DatesParserDelegate(learningYear: learningYear, semester: semester)
                xmlParser.delegate = parserDelegate
                xmlParser.parse()
                
                if let begin = parserDelegate.semesterBegin, end = parserDelegate.semesterEnd {
                    importLessons(fromDate: begin, toDate: end, forGroup: groupName)
                }
            }
        }
    }
    
    private init() {}
    
    private class func importLessons(fromDate begin : NSDate, toDate end : NSDate, forGroup groupName : String) {
        if jsonDictionary != nil {
            let store = EKEventStore()
            store.requestAccessToEntityType(EKEntityTypeEvent, completion: {
                (granted:Bool , error:NSError!) in
                if (granted) {
                    let lessons = ModelsInitializer.getLessons(forGroupName: groupName, fromJSON: self.jsonDictionary!)
                    let calendar = (store.calendarsForEntityType(EKEntityTypeEvent)! as? [EKCalendar])![0]
                    for lesson in lessons {
                        let event : EKEvent = lesson.getEvent(begin, semesterEnd : end, evStore : store, calendar: calendar)
                        let error = NSErrorPointer()
                        store.saveEvent(event, span: EKSpanFutureEvents, commit: false, error: error)
                        println(event)
                    }
                    let error = NSErrorPointer()
                    store.commit(error)
                }
            })
            
        }
    }
    
    static var jsonDictionary : NSDictionary? = CalendarSaver.getRasp()
    
    private class func getRasp() -> NSDictionary? {
        if let path = NSBundle.mainBundle().pathForResource("rasp", ofType: "json")
        {
            if let jsonData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)
            {
                return NSJSONSerialization.JSONObjectWithData(jsonData,
                    options: NSJSONReadingOptions.MutableContainers, error: nil) as? NSDictionary
            }
        }
        return nil
    }
}