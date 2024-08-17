//
//  WelcomeView.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/12/24.
//
import SwiftUI
import Combine
struct WelcomeView: View {
    @State private var showRegistration = false
    @State private var showLogin = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    FallingFoodView()
                        .edgesIgnoringSafeArea(.all)
                    VStack {
                        Spacer()
                        // Ketchup branding with larger white background
                        VStack(spacing: 10) {
                            Image("SkipFill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                            // Remove background
                            
                            Image("KetchupTextRed")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200)
                            
                            
                            HStack {
                                Text("Review Restaurants ")
                                    .font(.custom("MuseoSansRounded-500", size: 18))
                                    .foregroundStyle(.black)
                                +
                                Text("With Friends!")
                                    .font(.custom("MuseoSansRounded-700", size: 18))
                                    .foregroundStyle(.black)
                            }
                            
                            .padding()
                            .foregroundStyle(.black)
                            
                            
                        }
                        
            
                        
                        
                        Spacer()
                        
                        // Buttons at the bottom
                        VStack(spacing: 20) {
                            // Get Started button
                            Button(action: {
                                showRegistration = true
                            }) {
                                Text("Get Started")
                                    .font(.custom("MuseoSansRounded-300", size: 18))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(width: 300)
                                    .padding()
                                    .background(Color("Colors/AccentColor"))
                                    .cornerRadius(10)
                            }
                            
                            // Login option
                            HStack {
                                
                                Text("Beta user before 8/16?")
                                    .font(.custom("MuseoSansRounded-300", size: 16))
                                
                                Button(action: {
                                    showLogin = true
                                }) {
                                    Text("Log in")
                                        .font(.custom("MuseoSansRounded-300", size: 16))
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color("Colors/AccentColor"))
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 20)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.1), radius: 10)
                    }
                    .zIndex(1)  // Ensure content is above the falling food
                }
            }
            .navigationDestination(isPresented: $showRegistration) {
                PhoneAuthView()
            }
            .navigationDestination(isPresented: $showLogin) {
                LoginView()
            }
        }
    }
}

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
