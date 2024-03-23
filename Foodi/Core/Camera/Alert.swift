//
//  Alert.swift
//  Foodi
//
//  Created by Joe Ciminelli on 3/23/24.
//

import Foundation
import SwiftUI

struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let dismissButton: Alert.Button
}

struct AlertContext {
    static let deviceInput = AlertItem(title: "Invalid device input",
                                       message: "Something wrong with the camera",
                                       dismissButton: .default(Text("Ok")))
}
