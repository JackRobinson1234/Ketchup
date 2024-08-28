//
//  FallingFoodView.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/27/24.
//

import SwiftUI
import Foundation
import Combine
struct FallingFoodView: View {
    @StateObject private var viewModel: FallingFoodViewModel
    
    init(isStatic: Bool = false) {
        _viewModel = StateObject(wrappedValue: FallingFoodViewModel(isStatic: isStatic))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(viewModel.foodParticles) { particle in
                    particle.view
                        .position(particle.position)
                        .rotationEffect(.degrees(particle.rotation))
                }
            }
            .onAppear {
                viewModel.initializeParticles(screenSize: geometry.size)
            }
            .onReceive(viewModel.timer) { _ in
                viewModel.updateParticles(screenSize: geometry.size)
            }
        }
    }
}

class FallingFoodViewModel: ObservableObject {
    @Published var foodParticles = [FoodParticle]()
    let timer: Publishers.Autoconnect<Timer.TimerPublisher>
    let isStatic: Bool
    
    init(isStatic: Bool) {
        self.isStatic = isStatic
        self.timer = Timer.publish(every: isStatic ? 1 : 0.016, on: .main, in: .common).autoconnect()
    }
    
    func initializeParticles(screenSize: CGSize) {
        let particleCount = 24
        if isStatic{
            let particleCount = 50
        }
        foodParticles = (0..<particleCount).map { _ in
            FoodParticle(screenSize: screenSize, initiallyDistributed: true, isStatic: isStatic)
        }
    }
    
    func updateParticles(screenSize: CGSize) {
        guard !isStatic else { return }
        
        for i in 0..<foodParticles.count {
            if foodParticles[i].position.y > screenSize.height {
                foodParticles[i] = FoodParticle(screenSize: screenSize, initiallyDistributed: false, isStatic: isStatic)
            } else {
                foodParticles[i].position.y += foodParticles[i].speed
            }
        }
    }
}

struct FoodParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let size: CGFloat
    var speed: CGFloat
    var rotation: Double
    let view: AnyView
    
    init(screenSize: CGSize, initiallyDistributed: Bool, isStatic: Bool) {
        let validWidth = max(screenSize.width, 1)
        let validHeight = max(screenSize.height, 1)
        
        if initiallyDistributed {
            position = CGPoint(x: CGFloat.random(in: 0..<validWidth),
                               y: CGFloat.random(in: 0..<validHeight))
        } else {
            position = CGPoint(x: CGFloat.random(in: 0..<validWidth),
                               y: -20)
        }
        
        size = CGFloat.random(in: 40...50)
        speed = isStatic ? 0 : CGFloat.random(in: 0.15...0.4)
        rotation = isStatic ? 0 : Double.random(in: -15...15)
        
        let shape = Int.random(in: 0...6)
        let color = Color.red
        
        switch shape {
        case 0:
            view = AnyView(Image(systemName: "heart.fill").foregroundColor(color).font(.system(size: size)).opacity(0.2))
        case 1:
            view = AnyView(Image("frenchfries").resizable().scaledToFit().frame(width: size, height: size).opacity(0.2))
        case 2:
            view = AnyView(Image("hamburger").resizable().scaledToFit().frame(width: size, height: size).opacity(0.2))
        case 3:
            view = AnyView(Image("icecream").resizable().scaledToFit().frame(width: size, height: size).opacity(0.2))
        case 4:
            view = AnyView(Image("taco").resizable().scaledToFit().frame(width: size, height: size).opacity(0.2))
        case 5:
            view = AnyView(Image("hotdog").resizable().scaledToFit().frame(width: size, height: size).opacity(0.2))
        default:
            view = AnyView(Image("pizza").resizable().scaledToFit().frame(width: size, height: size).opacity(0.2))
        }
    }
}

// Extension to apply corner radius to specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    FallingFoodView()
}
