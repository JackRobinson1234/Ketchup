//
//  TabBarController.swift
//  Foodi
//
//  Created by Jack Robinson on 4/21/24.
//
import Foundation
import SwiftUI
import Combine
class TabBarController: ObservableObject {
    @Published var selectedTab = 0
    @Published var visibility: Visibility = .visible
    @Published var scrollToTop = false
    private var cancellable: AnyCancellable?
    @Published var showContacts = false
    init() {
        listenForTabSelection()
    }
    
    deinit {
        cancellable?.cancel()
        cancellable = nil
    }
    
    private func listenForTabSelection() {
        cancellable = $selectedTab
            .sink { [weak self] newTab in
                guard let self = self else { return }
                if newTab == self.selectedTab && newTab == 0{
                    print("SCROLL TO TOP TRUE")
                    scrollToTop.toggle()
                }
            }
    }
}
