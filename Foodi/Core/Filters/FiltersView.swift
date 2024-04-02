//
//  FiltersView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
enum FiltersViewOptions{
    case location
    case cuisine
    case price
    case noneSelected
}
struct FiltersView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedOption: FiltersViewOptions = .location
    @State private var locationText = ""
    @State private var cuisineText = ""
    @State var selectedCuisines: [String] = []
    
    
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading){
                if !locationText.isEmpty {
                    Button("Clear") {
                        locationText = ""
                    }
                    .foregroundStyle(.black)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                }
            }
            .padding()
            VStack {
                if selectedOption == .location {
                    VStack(alignment: .leading){
                        Text("Filter by Location")
                            .font(.title2)
                            .fontWeight(.semibold)
                        HStack{
                            Image(systemName: "magnifyingglass")
                                .imageScale(.small)
                            TextField("Search destinations", text: $locationText)
                                .font(.subheadline)
                                .frame(height:44)
                                .padding(.horizontal)
                        }
                        .frame(height: 44)
                        .padding(.horizontal)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(lineWidth: 1.0)
                                .foregroundStyle(Color(.systemGray4))
                        )
                    }
                    .modifier(CollapsibleFilterViewModifier())
                    .onTapGesture(count:2){
                        withAnimation(.snappy){ selectedOption = .noneSelected}
                    }
                    
                } else {
                    CollapsedPickerView(title: "Location", description: "Filter Location")
                        .onTapGesture{
                            withAnimation(.snappy){ selectedOption = .location}
                        }
                }
                
                
                VStack{
                    if selectedOption == .cuisine {
                        VStack(alignment: .leading){
                            cuisineFilters(selectedCuisines: $selectedCuisines)
                        }
                        .modifier(CollapsibleFilterViewModifier(frame: 275))
                        .onTapGesture(count:2){
                            withAnimation(.snappy){ selectedOption = .noneSelected}}
                    }
                    else {
                        if selectedCuisines.isEmpty {
                            CollapsedPickerView(title: "Cuisine", description: "Filter Cuisine")
                                .onTapGesture{
                                    withAnimation(.snappy){ selectedOption = .cuisine}
                                }
                        } else {
                            let count = selectedCuisines.count
                            CollapsedPickerView(title: "Cuisine", description: "\(count) Filters Selected")
                                .onTapGesture{
                                    withAnimation(.snappy){ selectedOption = .cuisine}
                                }
                        }
                    }
                }
                VStack{
                    if selectedOption == .price {
                        HStack{
                            Text("Show Expanded View")
                            
                            Spacer()
                        }
                        .modifier(CollapsibleFilterViewModifier())
                        .onTapGesture (count:2){
                            withAnimation(.snappy){ selectedOption = .noneSelected}
                        }
                    }
                    else {
                        CollapsedPickerView(title: "Price", description: "Filter Price")
                            .onTapGesture{
                                withAnimation(.snappy){ selectedOption = .price}
                            }
                    }
                }
            }
            Spacer()
        .navigationTitle("Add Filters")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .imageScale(.small)
                        .foregroundColor(.black)
                        .padding(6)
                        .overlay(
                            Circle()
                                .stroke(lineWidth: 1.0)
                                .foregroundColor(.gray)
                        )
                }
            }
        }
        }
    }
}

#Preview {
    FiltersView()
}


struct CollapsedPickerView: View {
    let title: String
    let description: String
    var height: CGFloat = 64
    var body: some View {
        VStack{
            HStack {
                Text(title)
                    .foregroundStyle(.gray)
                Spacer()
                
                Text(description)
            }
            .fontWeight(.semibold)
            .font(.subheadline)
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
        .shadow(radius: 10)
        
    }
}
