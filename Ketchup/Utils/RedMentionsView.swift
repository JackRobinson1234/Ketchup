//
//  RedMentionsView.swift
//  Ketchup
//
//  Created by Joe Ciminelli on 7/12/24.
//
import SwiftUI

struct RedMentionsTextView: View {
    
    let label: String
    let mentions: [PostUser]  // List of PostUser objects
    
    var body: some View {
        let words = label.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        
        // Combine the words into a single Text view
        let combinedText = words.enumerated().reduce(Text("")) { (result, element) -> Text in
            let (index, word) = element
            let separator = index == 0 ? "" : " "
            
            if word.hasPrefix("@"), let mention = mentions.first(where: { $0.username == String(word.dropFirst().split(separator: "'")[0]) }) {
                let mentionText = String(word.prefix(while: { $0 != "'" }))
                let remainingText = String(word.dropFirst(mentionText.count))
                
                return result + Text(separator) +
                    Text(mentionText).font(.custom("MuseoSansRounded-300", size: 16)).foregroundColor(.red) +
                    Text(remainingText).font(.custom("MuseoSansRounded-300", size: 16))
            } else {
                return result + Text(separator + word)
                    .font(.custom("MuseoSansRounded-300", size: 16))
            }
        }
        
        return HStack {
            combinedText
            Spacer()
        }
    }
}

struct RedMentionsTextView_Previews: PreviewProvider {
    static var previews: some View {
        let exampleCaption = "Check out @johnDoe's post and follow @janeDoe for more updates!"
        let exampleMentions = [
            PostUser(id: "1", fullname: "John Doe", profileImageUrl: nil, privateMode: false, username: "johnDoe"),
            PostUser(id: "2", fullname: "Jane Doe", profileImageUrl: nil, privateMode: false, username: "janeDoe")
        ]
        
        return RedMentionsTextView(label: exampleCaption, mentions: exampleMentions)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}









