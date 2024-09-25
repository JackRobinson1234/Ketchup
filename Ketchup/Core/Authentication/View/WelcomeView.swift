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
                                    .foregroundColor(.black)
                                +
                                Text("With Friends!")
                                    .font(.custom("MuseoSansRounded-700", size: 18))
                                    .foregroundColor(.black)
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

