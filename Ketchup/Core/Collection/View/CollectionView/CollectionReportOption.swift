//
//  Delete Option.swift
//  Foodi
//
//  Created by Jack Robinson on 5/12/24.
//

import SwiftUI

struct CollectionOptionsSheet: View {
    let collection: Collection
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAlert = false
    @State var showReportDetails = false
    @State var optionsSheetDismissed: Bool = false
    var body: some View {
        VStack(spacing: 20) {
                Button {
                    showReportDetails = true
                } label: {
                    Text("Report Collection")
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .foregroundColor(.black)
                        .bold()
                }
        }
        .onChange(of: optionsSheetDismissed) {
            if optionsSheetDismissed {
                dismiss()
            }
        }
        .onAppear {
            if optionsSheetDismissed {
                dismiss()
            }
        }
        .padding()
        .sheet(isPresented: $showReportDetails) {
            ReportingView(contentId: collection.id, objectType: "collection", dismissView: $optionsSheetDismissed )
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
                .onDisappear{
                    dismiss()
                }
                
        }
        
    }
}


//#Preview {
//    CollectionOptionsSheet(collection: Collection())
//}
