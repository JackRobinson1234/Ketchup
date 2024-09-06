//
//  SafariView.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/5/24.
//

import Foundation
import Foundation
import UIKit
import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UIViewController {
        let parsedURL = URLHandler.parseAndValidate(url.absoluteString)
        
        if let validURL = parsedURL {
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = false
            return SFSafariViewController(url: validURL, configuration: config)
        } else {
            return UIHostingController(rootView:
                                        SafariErrorView(urlString: url.absoluteString)
            )
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

struct SafariErrorView: View {
    let urlString: String
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
            Text("Error")
                .font(.title)
            Text("Unable to open URL: \(urlString)")
                .multilineTextAlignment(.center)
                .padding()
        }
        .onAppear {
            print("SafariErrorView: Displaying error for URL: \(urlString)")
        }
    }
}

class URLHandler {
    static func parseAndValidate(_ urlString: String) -> URL? {
        print("URLHandler: Starting to parse and validate URL: \(urlString)")
        
        var parsedString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        print("URLHandler: After cleanup: \(parsedString)")
        
        if !parsedString.lowercased().hasPrefix("http://") && !parsedString.lowercased().hasPrefix("https://") {
            parsedString = "https://" + parsedString
            print("URLHandler: Added https:// scheme: \(parsedString)")
        }
        
        guard let url = URL(string: parsedString),
              let host = url.host, !host.isEmpty else {
            print("URLHandler: Invalid URL or missing host")
            return nil
        }
        
        print("URLHandler: URL validation successful: \(url)")
        return url
    }
}

struct LinkItem: Identifiable {
    let id: String
    let url: String
    
    var validURL: URL? {
        return URL(string: url)
    }
}
