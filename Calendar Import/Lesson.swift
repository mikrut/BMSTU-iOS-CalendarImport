//
//  Lesson.swift
//  Calendar Import
//
//  Created by Андрей on 14.08.15.
//  Copyright (c) 2015 BMSTU. All rights reserved.
//

import Foundation
import EventKit

public class Lesson {
    static var lectureName = "Лекция"
    static var laboratoryName = "Лабораторная работа"
    static var seminarName = "Семинар"
    
    class func getTerm(term : String) -> RepeatType {
        // term ::= 17-all | 17-w1 | 17-w2
        switch (term[advance(term.startIndex, 4)]) {
        case "1":
            return RepeatType.NUMERATOR
        case "2":
            return RepeatType.DENOMINATOR
        case "l": fallthrough
        default:
            return RepeatType.ALL
        }
    }
    
    static let timetable : [(begin : (h:Int, m:Int), end : (h:Int, m:Int))] = [
        ((08, 30), (10, 05)),
        ((10, 15), (11, 50)),
        ((12, 00), (13, 35)),
        ((13, 50), (15, 25)),
        ((15, 40), (17, 15)),
        ((17, 25), (19, 00)),
        ((19, 10), (20, 45))
    ]
    
    class func getName(names : String...) -> String {
        var maxLen = names[0].lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        var maxInd = 0
        
        for (index, name) in enumerate(names) {
            if (name.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) >= maxLen) {
                maxLen = name.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
                maxInd = index
            }
        }
        
        return names[maxInd]
    }
    
    class func getLessonType(uid : String) -> LessonType {
        let lectureRegex = "^.*-l$"
        let seminarRegex = "^.*-s$"
        let laboratoryRegex = "^.*-a$"
        
        if let match = uid.rangeOfString(lectureRegex, options: .RegularExpressionSearch) {
            return .LECTURE
        } else if let match = uid.rangeOfString(laboratoryRegex, options: .RegularExpressionSearch) {
            return .LABORATORY
        }
        return .SEMINAR
    }
    
    enum RepeatType {
        case ALL
        case NUMERATOR
        case DENOMINATOR
    }
    
    enum ActivityType {
        case DISC
        case CUSTOM
    }
    
    enum LessonType {
        case LECTURE
        case SEMINAR
        case LABORATORY
        
        func toString() -> String {
            switch (self) {
            case LECTURE:
                return lectureName
            case .LABORATORY:
                return laboratoryName
            default:
                return seminarName
            }
        }
    }
    
    var pairIndex = 0
    var repeatType = RepeatType.ALL
    var wday = 0 // Day of week
    var auditoriums : [String] = []
    var lecturers : [String] = []
    var name : String!
    var groups : [String] = []
    var lessonType = LessonType.SEMINAR
    var activityType = ActivityType.DISC
    
    init(jsonLesson : NSDictionary) {
        
        if let time = jsonLesson["time"] as? String {
            pairIndex = time.toInt()!
        }
        
        if let term = jsonLesson["term"] as? String {
            repeatType = Lesson.getTerm(term)
        }
        
        if let wday = jsonLesson["wday"] as? Int {
            self.wday = wday
        }
        
        if let auds = jsonLesson["aud"] as? NSArray {
            auditoriums = ModelsInitializer.extractAuds(auds)
        }
        
        if let pubs = jsonLesson["pub"] as? NSArray {
            lecturers = ModelsInitializer.extractPubs(pubs)
        }
        
        if let time = jsonLesson["time"] as? NSArray {
            if let index = time[0] as? String {
                pairIndex = index.toInt()!
            }
        }
        
        if let activity = jsonLesson["activity"] as? NSDictionary {
            if let actType = activity["type"] as? String {
                if actType == "custom" {
                    activityType = ActivityType.CUSTOM
                }
            }
            
            name = Lesson.getName(
                (activity["name1"] as? String)!,
                (activity["name2"] as? String)!,
                (activity["name3"] as? String)!
                )
            
            if let id = activity["id"] as? String {
                lessonType = Lesson.getLessonType(id)
            }
        }
        
        if let groups = jsonLesson["groups"] as? NSArray {
            self.groups = ModelsInitializer.extractGroups(groups)
        }
    }
    
    func getAud() -> String {
        return ", ".join(auditoriums)
    }
    
    func getEvent(semesterStart : NSDate, semesterEnd : NSDate, evStore : EKEventStore, calendar: EKCalendar) -> EKEvent {
        var event = EKEvent(eventStore: evStore)
        event.title = name
        event.allDay = false
        event.availability = EKEventAvailabilityBusy
        event.location = "МГТУ:  " + getAud()
        event.calendar = calendar
        
        let gregorian = NSCalendar(calendarIdentifier: NSGregorianCalendar)!
        let startComponents = gregorian.components(.CalendarUnitWeekday |  .CalendarUnitWeekOfYear | .CalendarUnitYear, fromDate: semesterStart)
        
        let MONDAY = 2
        var weekOfYear = startComponents.weekOfYear
        if (wday < startComponents.weekday - MONDAY && self.repeatType != .DENOMINATOR) {
            weekOfYear += self.repeatType == .ALL ? 1 : 2
        }
        if (self.repeatType == .DENOMINATOR) {
            ++weekOfYear
        }
        
        let pair = Lesson.timetable[pairIndex]
        
        var beginComponents = NSDateComponents()
        beginComponents.year = startComponents.year
        beginComponents.weekOfYear  = weekOfYear;
        beginComponents.weekday = wday + MONDAY;
        beginComponents.hour    = pair.begin.h
        beginComponents.minute  = pair.begin.m
        beginComponents.second  = 0
        beginComponents.nanosecond = 0
        
        event.startDate = gregorian.dateFromComponents(beginComponents)
        
        beginComponents.hour = pair.end.h
        beginComponents.minute = pair.end.m
        event.endDate = gregorian.dateFromComponents(beginComponents)
        
        let recurInterval = self.repeatType == .ALL ? 1 : 2
        let rule = EKRecurrenceRule(recurrenceWithFrequency: EKRecurrenceFrequencyWeekly, interval: recurInterval, end: (EKRecurrenceEnd.recurrenceEndWithEndDate(semesterEnd) as? EKRecurrenceEnd)!)
        event.addRecurrenceRule(rule)
        
        return event
    }
    
}