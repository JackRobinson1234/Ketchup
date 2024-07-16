//
//  TaggedTextView.swift
//  Ketchup
//
//  Created by Joe Ciminelli on 7/11/24.
//

import Foundation
import SwiftUI

struct TaggedTextView: View {
    let text: String
    let tagColor: Color
    
    var body: some View {
        let words = text.split(separator: " ").map(String.init)
        return HStack {
            ForEach(words, id: \.self) { word in
                if word.starts(with: "@") {
                    Text(word)
                        .foregroundColor(tagColor)
                        .fontWeight(.semibold)
                } else {
                    Text(word)
                        .foregroundColor(.primary)
                }
            }
        }
    }
}
