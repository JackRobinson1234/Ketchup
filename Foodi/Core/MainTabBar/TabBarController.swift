//
//  TabBarController.swift
//  Foodi
//
//  Created by Jack Robinson on 4/21/24.
//
import Foundation
import SwiftUI
class TabBarController: ObservableObject {
    @Published var selectedTab = 0
    @Published var visibility = Visibility.visible
}
