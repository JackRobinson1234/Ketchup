//
//  Reporting View.swift
//  Foodi
//
//  Created by Jack Robinson on 5/11/24.
//

import SwiftUI

import SwiftUI

struct ReportingView: View {
    var contentId: String
    var objectType: String
    @Environment(\.dismiss) var dismiss
    @State private var selectedReasons: [String] = []
    @State private var customReason: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Binding var dismissView: Bool
    @FocusState private var fieldIsActive: Bool
    
    var commonReasons = ["Spam", "Inappropriate Content", "Harassment", "Offensive Language"]
    
    var body: some View {
        ScrollView{
            VStack(alignment: .leading) {
                HStack{
                    Spacer()
                    Text("Report this \(objectType)")
                        .bold()
                    Spacer()
                }
                VStack(alignment: .leading) {
                    ForEach(commonReasons, id: \.self) { reason in
                        Toggle(isOn: reasonIsSelected(reason)) {
                            Text(reason)
                        }
                    }
                    Text("Other:")
                        .padding(.top)
                    TextField("Custom Reason (optional)", text: $customReason)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($fieldIsActive)
                    
                    Text("Characters remaining: \(150 - customReason.count)")
                        .foregroundColor(.primary)
                        .font(.custom("MuseoSansRounded-300", size: 10))
                        .onChange(of: customReason) {oldValue, newValue in
                               if newValue.count > 50 {
                                   customReason = String(newValue.prefix(150))
                               }
                           }
                }
                .padding()
                
                Button {
                    Task {
                        do {
                            var reasons: [String] = selectedReasons
                            if !customReason.isEmpty && customReason.count <= 150 {
                                reasons.append(customReason)
                            }
                            
                            try await ReportService.shared.uploadReport(contentId: contentId, reasons: reasons, status: "pending", objectType: objectType)
                            alertMessage = "Report submitted successfully!"
                            dismissView = true
                            showAlert = true
                        } catch {
                            alertMessage = "Error uploading report: \(error.localizedDescription)"
                            dismissView = true
                            showAlert = true
                        }
                    }
                } label: {
                    Text("Report")
                        .modifier(StandardButtonModifier())
                }
                .disabled(selectedReasons.isEmpty && customReason.isEmpty) // Disable the button if both selectedReasons and customReason are empty
                .opacity((selectedReasons.isEmpty && customReason.isEmpty) ? 0.5 : 1.0) // Reduce opacity if both selectedReasons and customReason are empty
                .padding()
            }
            
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Report Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")) {
                    dismiss()
                })
                    
            }
            .padding()
        }
    }
    
    private func reasonIsSelected(_ reason: String) -> Binding<Bool> {
        Binding(
            get: {
                selectedReasons.contains(reason)
            },
            set: { isSelected in
                if isSelected {
                    selectedReasons.append(reason)
                } else {
                    selectedReasons.removeAll { $0 == reason }
                }
            }
        )
    }
}

struct ReportingView_Previews: PreviewProvider {
    static var previews: some View {
        ReportingView(contentId: "123", objectType: "comment", dismissView: .constant(false))
    }
}
