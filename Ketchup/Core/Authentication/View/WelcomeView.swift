//
//  WelcomeView.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/12/24.
//
import SwiftUI

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
                                +
                                Text("With Friends!")
                                    .font(.custom("MuseoSansRounded-700", size: 18))
                            }
                            
                            .padding()
                            .foregroundStyle(.black)
                            
                            
                        }
                        
                        
                        //.padding(.horizontal, 15)
                        //.padding(.vertical, 20)
                        //                    .background(Color.white)
                        //                    .cornerRadius(5)
                        // .shadow(color: Color.black.opacity(0.1), radius: 10)
                        
                        
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
    @State private var foodParticles = [FoodParticle]()
    
    let timer = Timer.publish(every: 0.005, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(foodParticles) { particle in
                    particle.view
                        .position(particle.position)
                        .rotationEffect(.degrees(particle.rotation))
                        .animation(.linear(duration: 0.01), value: particle.position)
                }
            }
            .onAppear {
                let particleCount = 24
                let immediateParticles = 5 // Number of particles to drop immediately
                let totalDuration = 10.0 // Total time to stagger remaining particles
                
                // Add the first few particles immediately
                for _ in 0..<immediateParticles {
                    foodParticles.append(FoodParticle(screenSize: geometry.size))
                }
                
                // Stagger the remaining particles
                for i in immediateParticles..<particleCount {
                    let delay = (totalDuration / Double(particleCount - immediateParticles)) * Double(i - immediateParticles)
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        foodParticles.append(FoodParticle(screenSize: geometry.size))
                    }
                }
            }
            .onReceive(timer) { _ in
                for i in 0..<foodParticles.count {
                    if foodParticles[i].position.y > geometry.size.height {
                        foodParticles[i] = FoodParticle(screenSize: geometry.size)
                    } else {
                        foodParticles[i].position.y += foodParticles[i].speed
                    }
                }
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
    
    init(screenSize: CGSize) {
        let validWidth = max(screenSize.width, 1) // Ensure the width is at least 1 to avoid an empty range
        
        position = CGPoint(x: CGFloat.random(in: 0..<validWidth),
                           y: -20)
        size = CGFloat.random(in: 40...50)
        speed = CGFloat.random(in: 0.15...0.4)
        rotation = Double.random(in: -15...15)
        
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
