//
//  ActivityCell.swift
//  Foodi
//
//  Created by Jack Robinson on 5/2/24.
//

import SwiftUI
import Kingfisher
import FirebaseFirestoreInternal
import Firebase


func getTimeElapsedString(from timestamp: Timestamp) -> String {
    let calendar = Calendar.current
    let now = Date()
    let date = timestamp.dateValue()
    
    let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date, to: now)
    
    if let year = components.year, year > 0 {
        return "\(year)y ago"
    } else if let month = components.month, month > 0 {
        return "\(month)mo ago"
    } else if let day = components.day, day > 0 {
        if day == 1 {
            return "Yesterday"
        }
        return "\(day)d ago"
    } else if let hour = components.hour, hour > 0 {
        return "\(hour)h ago"
    } else if let minute = components.minute, minute > 0 {
        return "\(minute)m ago"
    } else {
        return "Just now"
    }
}
