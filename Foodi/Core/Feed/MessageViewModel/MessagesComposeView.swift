//
//  MessagesComposeView.swift
//  Foodi
//
//  Created by Jack Robinson on 3/3/24.
//
import SwiftUI
import MessageUI

//Debug when on the app store
struct MessageComposeView: UIViewControllerRepresentable {
    let messageBody: String
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let messageComposeVC = MFMessageComposeViewController()
        messageComposeVC.body = messageBody
        messageComposeVC.messageComposeDelegate = context.coordinator
        return messageComposeVC
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {
        // Update the view controller if needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        var parent: MessageComposeView

        init(parent: MessageComposeView) {
            self.parent = parent
        }

        func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                          didFinishWith result: MessageComposeResult) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
