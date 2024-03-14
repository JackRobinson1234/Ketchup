//
//  CameraViewModel.swift
//  Foodi
//
//  Created by Joe Ciminelli on 3/10/24.
//

import SwiftUI

class CameraViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    let cameraService = CameraService()
}
