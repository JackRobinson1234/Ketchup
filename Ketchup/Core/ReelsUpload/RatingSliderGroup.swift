//
//  ReviewSlideBar.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/9/24.
//

import SwiftUI
struct RatingSliderGroup: View {
    let label: String
    @Binding var rating: Double
    @Binding var isNA: Bool
    
    var formattedRating: String {
        isNA ? "N/A" : String(format: "%.1f", rating)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack (alignment: .bottom) {
                Text(label)
                    .font(.custom("MuseoSansRounded-500", size: 16))
                    .foregroundColor(.black)
                Spacer()
                HStack(alignment: .bottom){
                    Text(formattedRating)
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .foregroundColor(.black)
                    
                    if !isNA {
                        Text("/ 10.0")
                            .font(.custom("MuseoSansRounded-300", size: 16))
                            .foregroundColor(.black)
                        
                    }
                }
                .frame(width: 80)
            }
            HStack{
                Button(action: {
                    isNA.toggle()
                    if !isNA {
                        rating = 5.0 // Reset to default value when switching back from N/A
                    }
                }) {
                    Text("N/A")
                        .font(.custom("MuseoSansRounded-300", size: 14))
                        .foregroundColor(isNA ? .white : .gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isNA ? Color.red : Color.clear)
                                .stroke(isNA ? Color.red : Color.gray, lineWidth: 1)
                        )
                }
                .frame(width: 50)
                
                
                
                HStack{
                    Slider(value: Binding(
                        get: { self.rating },
                        set: {
                            self.rating = $0
                            if isNA {
                                isNA = false
                            }
                        }
                    ), in: 0...10, step: 0.5)
                    .opacity(isNA ? 0.2 : 1.0)
                    
                }
            }
        }
        .onAppear {
            UISlider.appearance().setThumbImage(nil, for: .normal)
        }
    }
}
