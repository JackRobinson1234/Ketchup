//
//  Testing.swift
//  Ketchup
//
//  Created by Joe Ciminelli on 7/14/24.
//

import SwiftUI

struct TestContentView: View {
    let text = "hi my name is @joe and my friend is @jane"
    let users: [PostUser]
    let navigate: (String) -> Void  // Now navigates using user ID
    
    var body: some View {
        Text(parseText(text))
            .environment(\.openURL, OpenURLAction { url in
                if url.scheme == "user",
                   let userId = url.host {
                    navigate(userId)
                    return .handled
                }
                return .systemAction
            })
    }
    
    func parseText(_ input: String) -> AttributedString {
        var result = AttributedString(input)
        let pattern = "@\\w+"
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return result
        }
        
        let nsRange = NSRange(input.startIndex..., in: input)
        let matches = regex.matches(in: input, range: nsRange)
        
        for match in matches.reversed() {
            guard let range = Range(match.range, in: input) else { continue }
            
            let fullMatch = String(input[range])
            let username = String(fullMatch.dropFirst()) // Remove @ from username
            
            if let user = users.first(where: { $0.username.lowercased() == username.lowercased() }),
               let attributedRange = Range(range, in: result) {
                result[attributedRange].foregroundColor = Color("Colors/AccentColor")
                result[attributedRange].link = URL(string: "user://\(user.id)")
            }
        }
        
        return result
    }
}

struct TestUserProfileView: View {
    let user: PostUser
    
    var body: some View {
        VStack {
            Text("User Profile for: \(user.fullname)")
            Text("Username: @\(user.username)")
            if let profileImageUrl = user.profileImageUrl {
                AsyncImage(url: URL(string: profileImageUrl)) { image in
                    image.resizable().scaledToFit().frame(width: 100, height: 100)
                } placeholder: {
                    ProgressView()
                }
            }
            Text("Private Mode: \(user.privateMode ? "On" : "Off")")
        }
    }
}

struct TestRootView: View {
    @State private var path = NavigationPath()
    let users: [PostUser] = [
        PostUser(id: "1", fullname: "Joe Smith", privateMode: false, username: "joe"),
        PostUser(id: "2", fullname: "Jane Doe", profileImageUrl: "https://example.com/jane.jpg", privateMode: true, username: "jane")
    ]
    
    var body: some View {
        NavigationStack(path: $path) {
            TestContentView(users: users, navigate: { userId in
                if let user = users.first(where: { $0.id == userId }) {
                    path.append(user)
                }
            })
            .navigationDestination(for: PostUser.self) { user in
                TestUserProfileView(user: user)
            }
        }
    }
}

struct TestContentView_Previews: PreviewProvider {
    static var previews: some View {
        TestRootView()
    }
}





