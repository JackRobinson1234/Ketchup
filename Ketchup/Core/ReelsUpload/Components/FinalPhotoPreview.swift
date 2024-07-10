//
//  FinalPhotoPreview.swift
//  Foodi
//
//  Created by Jack Robinson on 5/14/24.
//

import SwiftUI

struct FinalPhotoPreview: View {
    
    @ObservedObject var uploadViewModel: UploadViewModel
    
    @State private var currentPage = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                TabView(selection: $currentPage) {
                    ForEach(uploadViewModel.images!.indices, id: \.self) { index in
                        if uploadViewModel.fromInAppCamera {
                            Image(uiImage: uploadViewModel.images![index])
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipped()
                                .tag(index)
                        } else {
                            Image(uiImage: uploadViewModel.images![index])
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipped()
                                .tag(index)
                        }
                    }
                }
                .background(.primary)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            }
        }
    }
}

//#Preview {
//    FinalPhotoPreview()
//}
