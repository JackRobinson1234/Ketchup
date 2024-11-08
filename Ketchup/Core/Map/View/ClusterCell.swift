//
//  ClusterCell.swift
//  Foodi
//
//  Created by Jack Robinson on 5/23/24.
//

import SwiftUI
import MapKit



struct ClusterCell: View {
    let cluster: ExampleClusterAnnotation
    var selectedRestaurantId: String?
    @State private var scale: CGFloat = 1.0
    
    private var containsSelectedRestaurant: Bool {
        guard let selectedId = selectedRestaurantId else { return false }
        return cluster.memberAnnotations.contains { $0.restaurant.id == selectedId }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 30, height: 30)
                .overlay(
                    Circle()
                        .stroke(Color("Colors/AccentColor"), lineWidth: 2)
                )
            Text("\(cluster.count)")
                .foregroundColor(.black)
                .font(.custom("MuseoSansRounded-300", size: 12))
        }
        .scaleEffect(scale)
        .onChange(of: containsSelectedRestaurant) { isSelected in
            if isSelected {
                bounce()
            } else {
                withAnimation(.spring()) {
                    scale = 1.0
                }
            }
        }
    }
    
    private func bounce() {
        scale = 1.0 // Reset scale before animation
        withAnimation(Animation.interpolatingSpring(stiffness: 300, damping: 5)) {
            scale = 1.5
        }
        withAnimation(Animation.spring().delay(0.2)) {
            scale = 1.2
        }
    }
}

struct LargeClusterCell: View {
    let cluster: LargeClusterAnnotation
    var selectedRestaurantId: String?
    @State private var scale: CGFloat = 1.0
    
    private var containsSelectedRestaurant: Bool {
        guard let selectedId = selectedRestaurantId else { return false }
        return cluster.memberAnnotations.contains { $0.id == selectedId }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color("Colors/AccentColor"))
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
            Text("\(cluster.count)")
                .foregroundColor(.white)
                .font(.custom("MuseoSansRounded-500", size: 14))
        }
        .scaleEffect(scale)
        .onChange(of: containsSelectedRestaurant) { isSelected in
            if isSelected {
                bounce()
            } else {
                withAnimation(.spring()) {
                    scale = 1.0
                }
            }
        }
    }
    
    private func bounce() {
        scale = 1.0 // Reset scale before animation
        withAnimation(Animation.interpolatingSpring(stiffness: 300, damping: 5)) {
            scale = 1.5
        }
        withAnimation(Animation.spring().delay(0.2)) {
            scale = 1.2
        }
    }
}
