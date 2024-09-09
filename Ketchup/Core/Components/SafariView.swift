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
            //print("SafariErrorView: Displaying error for URL: \(urlString)")
        }
    }
}

class URLHandler {
    static func parseAndValidate(_ urlString: String) -> URL? {
        //print("URLHandler: Starting to parse and validate URL: \(urlString)")
        
        var parsedString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        //print("URLHandler: After cleanup: \(parsedString)")
        
        // Handle "/url?q=http://" and similar cases
        if parsedString.hasPrefix("/url?q=") {
            parsedString = String(parsedString.dropFirst(7))
            if let endIndex = parsedString.firstIndex(of: "&") {
                parsedString = String(parsedString[..<endIndex])
            }
            parsedString = parsedString.removingPercentEncoding ?? parsedString
            //print("URLHandler: Removed '/url?q=' prefix: \(parsedString)")
        }
        
        // Handle "www." prefix without a scheme
        if parsedString.lowercased().hasPrefix("www.") && !parsedString.lowercased().hasPrefix("http") {
            parsedString = "https://" + parsedString
            //print("URLHandler: Added https:// scheme to www.: \(parsedString)")
        }
        
        // Add "https://" if no scheme is present
        if !parsedString.lowercased().hasPrefix("http://") && !parsedString.lowercased().hasPrefix("https://") {
            parsedString = "https://" + parsedString
            //print("URLHandler: Added https:// scheme: \(parsedString)")
        }
        
        // Remove any trailing slashes
        while parsedString.hasSuffix("/") {
            parsedString.removeLast()
        }
        
        guard let url = URL(string: parsedString),
              let host = url.host, !host.isEmpty else {
            //print("URLHandler: Invalid URL or missing host")
            return nil
        }
        
        // Additional validation: Check for valid TLD
        let validTLDs = ["com", "org", "net", "edu", "gov", "io", "co", "app", "dev"]
        let hostComponents = host.components(separatedBy: ".")
        guard hostComponents.count >= 2,
              let tld = hostComponents.last,
              validTLDs.contains(tld.lowercased()) else {
            //print("URLHandler: Invalid or missing TLD")
            return nil
        }
        
        //print("URLHandler: URL validation successful: \(url)")
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
