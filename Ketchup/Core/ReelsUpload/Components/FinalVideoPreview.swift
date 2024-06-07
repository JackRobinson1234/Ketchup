//
//  FinalVideoPreview.swift
//  Foodi
//
//  Created by Jack Robinson on 5/14/24.
//

import SwiftUI
import AVFoundation

struct FinalVideoPreview: View {
    
    @ObservedObject var uploadViewModel: UploadViewModel
    
    var body: some View {
        
        if let url = uploadViewModel.videoURL {
            let player = AVPlayer(url: url)
            ZStack {
                if uploadViewModel.fromInAppCamera {
                    VideoPlayer(player: player, videoGravity: .resizeAspectFill)
                } else {
                    VideoPlayer(player: player, videoGravity: .resizeAspect)
                }
            }
        }
    }
}

//#Preview {
//    FinalVideoPreview()
//}
