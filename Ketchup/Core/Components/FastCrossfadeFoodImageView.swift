//
//  FoodProgressView.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/16/24.
//

import SwiftUI

struct FastCrossfadeFoodImageView: View {
    let foodImages = ["frenchfries", "hamburger", "icecream", "taco", "hotdog", "pizza"]
    @State private var currentImageIndex = 0
    @State private var nextImageIndex = 1
    @State private var currentOpacity = 1.0
    @State private var nextOpacity = 0.0
    
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack{
            ZStack {
                Image(foodImages[currentImageIndex])
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .opacity(currentOpacity)
                
                Image(foodImages[nextImageIndex])
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .opacity(nextOpacity)
            }
            .onReceive(timer) { _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentOpacity = 0.0
                    nextOpacity = 1.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    currentImageIndex = nextImageIndex
                    nextImageIndex = (nextImageIndex + 1) % foodImages.count
                    currentOpacity = 1.0
                    nextOpacity = 0.0
                }
            }
            Text("Loading...")
                .font(.custom("MuseoSansRounded-500", size: 12))
                .foregroundStyle(Color("Colors/AccentColor"))
        }
       
    }
}

struct FastCrossfadeFoodImageView_Previews: PreviewProvider {
    static var previews: some View {
        FastCrossfadeFoodImageView()
    }
}
