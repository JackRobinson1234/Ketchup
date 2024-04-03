//
//  recipeTimePicker.swift
//  Foodi
//
//  Created by Jack Robinson on 3/7/24.
//

import SwiftUI
/*
struct RecipeTimePicker: View {
    @ObservedObject var viewModel: UploadPostViewModel
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack{
            VStack{
                HStack{
                    Spacer()
                    Button{
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.subheadline)
                    }
                    
                }
                .padding()
                Spacer()
                VStack{
                    Text("Select a Total Recipe Time")
                        .font(.subheadline)
                    HStack {
                        // Hours Picker
                        Picker("Hours", selection: $viewModel.recipeHours) {
                            ForEach(0..<24) { hour in
                                Text("\(hour)")
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80)
                        .padding(.top, 30)
                        
                        Text("hours")
                        
                        // Minutes Picker
                        Picker("Minutes", selection: $viewModel.recipeMinutes) {
                            ForEach(0..<60) { minute in
                                Text("\(minute)")
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        
                        .padding(.top, 30)
                        
                        Text("minutes")
                    }
                    .padding()
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    RecipeTimePicker(viewModel: UploadPostViewModel(service: UploadPostService(), restaurant: nil))
}
*/
