//
//  NavigationLazyLoad.swift
//  Foodi
//
//  Created by Jack Robinson on 2/20/24.
//

import Foundation
import SwiftUI

struct NavigationLazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: Content {
        build()
    }
}
