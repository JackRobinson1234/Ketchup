//
//  GoodForSelectionView.swift
//  Ketchup
//
//  Created by Jack Robinson on 10/18/24.
//

import SwiftUI

struct GoodForSelectionView: View {
    @Binding var selectedOptions: [String]
    @Environment(\.dismiss) var dismiss
    @State private var optionsSelected: Set<String> = []
    @State private var showingLimitAlert = false
    let goodForOptions: [String: [String]] = [
        "Activity": ["Live Music", "People Watching", "Watching Sports", "Catching up with Friends", "Dancing", "Bars with Food", "Trivia Nights", "Getting Work Done"],
        "Dietary": ["Very Healthy", "Kind of Healthy", "Not Healthy, but Good",],
        "Occasion": ["Big Groups", "Birthdays", "Corporate Card", "Formal Dates", "First Dates", "Solo Dining", "Impressing Out of Towners", "Coffee Date", "Happy Hours"],
        "Price": ["Cheap Food", "Cheap Drinks", "Worth the Splurge", "Not Worth It"],
        "Time of day": ["Quick Breakfast", "Sit Down Breakfast", "Brunch", "Quick Lunch", "Formal Lunch",  "Afternoon Tea", "Day Drinking", "Casual Dinner", "Formal Dinner", "Dessert", "Late Night Munchies"],
        "Vibe": ["Famous", "Trendy", "Historic", "Pet Friendly", "Great Cocktails", "Great Wine", "Good for Kids", "Sitting Outside", "Street Eats", "Incredible Views"]
    ]
    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 10)
    ]
    var body: some View {
        NavigationView {
            ScrollView {
                ForEach(goodForOptions.keys.sorted(), id: \.self) { category in
                    VStack(alignment: .leading) {
                        Text(category)
                            .font(.custom("MuseoSansRounded-700", size: 16))
                            .padding(.horizontal)
                            .padding(.top)
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                            ForEach(goodForOptions[category] ?? [], id: \.self) { option in
                                Button(action: {
                                    if optionsSelected.contains(option) {
                                        optionsSelected.remove(option)
                                    } else {
                                        if optionsSelected.count < 5 {  // Changed limit to 5
                                            optionsSelected.insert(option)
                                        } else {
                                            showingLimitAlert = true
                                            // Optional haptic feedback
                                            let generator = UINotificationFeedbackGenerator()
                                            generator.notificationOccurred(.error)
                                        }
                                    }
                                }) {
                                    Text(option)
                                        .font(.custom("MuseoSansRounded-500", size: 14))
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(optionsSelected.contains(option) ? Color.red : Color.clear)
                                        .foregroundColor(optionsSelected.contains(option) ? .white : Color.red)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.red, lineWidth: 1)
                                        )
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("Selected \(optionsSelected.count)/5")  // Update navigation title to reflect 5
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            }, trailing: Button("Done") {
                selectedOptions = Array(optionsSelected)
                dismiss()
            })
            .onAppear {
                optionsSelected = Set(selectedOptions)
            }
            .alert(isPresented: $showingLimitAlert) {
                Alert(
                    title: Text("Maximum Selection Reached"),
                    message: Text("You can only select up to 5 options."),  // Updated message
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}
