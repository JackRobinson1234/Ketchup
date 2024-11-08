//
//  ClusterCell.swift
//  Foodi
//
//  Created by Jack Robinson on 5/23/24.
//

import SwiftUI
import MapKit



struct LargeClusterCell: View {
    var cluster: LargeClusterAnnotation
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(Color("Colors/AccentColor"), lineWidth: 2)
                )
            Text("\(cluster.count)")
                .foregroundColor(.black)
                .font(.custom("MuseoSansRounded-300", size: 10))
        }
    }
}
struct ClusterCell: View {
    var cluster: ExampleClusterAnnotation
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(Color("Colors/AccentColor"), lineWidth: 2)
                )
            Text("\(cluster.count)")
                .foregroundColor(.black)
                .font(.custom("MuseoSansRounded-300", size: 10))
        }
    }
}
