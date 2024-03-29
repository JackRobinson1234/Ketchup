//
//  Debouncer.swift
//  Foodi
//
//  Created by Jack Robinson on 3/30/24.
//
import SwiftUI
import Combine
class Debouncer {
    let delay: TimeInterval
    var timer: Timer?

    init(delay: TimeInterval) {
        self.delay = delay
    }

    func schedule(action: @escaping () -> Void) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            action()
        }
    }
}
