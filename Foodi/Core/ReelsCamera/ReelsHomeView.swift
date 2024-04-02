//
//  ReelsCameraView.swift
//  Foodi
//
//  Created by Joe Ciminelli on 4/1/24.
//

import Foundation
import SwiftUI

struct ReelsHomeView: View {
    var body: some View {
        
        ZStack(alignment: .bottom) {
            
            // MARK: Camera View
            
            // MARK: Controls
            ZStack {
                
                Button {
                    
                } label: {
                    Image("Reels")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.black)
                        .padding(12)
                        .frame(width: 60, height: 60)
                        .background {
                            Circle()
                                .stroke(.black)
                        }
                        .padding(6)
                        .background {
                            Circle()
                                .fill(.white)
                        }
                }

                Button {
                    
                } label: {
                    Label {
                      Image(systemName: "chevron.right")
                            .font(.callout)
                    } icon: {
                        Text("Preview")
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background {
                        Capsule()
                            .fill(.white)
                    }
                    
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(maxHeight: .infinity, alignment: .bottom )
            .padding(.bottom, 10)
            .padding(.bottom, 30)
        }
        .preferredColorScheme(/*@START_MENU_TOKEN@*/.dark/*@END_MENU_TOKEN@*/)
        
    }
}


struct ReelsCameraView_Preview: PreviewProvider {
    static var previews: some View {
        ReelsHomeView()
    }
}
