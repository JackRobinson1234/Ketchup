//
//  MessagesComposeView.swift
//  Foodi
//
//  Created by Jack Robinson on 3/3/24.
//
import SwiftUI
import MessageUI
struct MessageComposeView: UIViewControllerRepresentable {
    let messageBody: String
    let mediaData: Data
    let mediaType: String
    @State private var isLoading = false
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let composeVC = MFMessageComposeViewController()
        composeVC.messageComposeDelegate = context.coordinator
        
        
        if mediaType == "video"{
            composeVC.addAttachmentData(mediaData, typeIdentifier: "public.mpeg-4", filename: "video.mp4")
        } else if mediaType == "photo" {
            composeVC.addAttachmentData(mediaData, typeIdentifier: "public.jpeg", filename: "image.jpg")

        }
        composeVC.body = messageBody
        return composeVC
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {
        // Update the view controller if needed
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            // Handle message composition result if needed
            controller.dismiss(animated: true, completion: nil)
        }
    }
}
