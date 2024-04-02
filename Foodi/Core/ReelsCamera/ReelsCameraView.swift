//
//  ReelscameraModelView.swift
//  Foodi
//
//  Created by Joe Ciminelli on 4/2/24.
//

import AVFoundation
import SwiftUI

struct NewcameraModelView: View {
    
    @StateObject var cameraModel = NewcameraModelModel()
    
    var body: some View {
        ZStack {
            // Going to be cameraModel preview
            NewcameraModelPreview(cameraModel: cameraModel)
                .ignoresSafeArea(.all, edges: .all)
            
            VStack {
                
                if cameraModel.isTaken {
                    
                    HStack {
                        
                        Spacer()
                        
                        Button {
                            cameraModel.untakePic()
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath.cameraModel")
                                .foregroundColor(.black)
                                .padding()
                                .background(Color.white)
                                .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                        }
                        .padding(.trailing, 10)
                    }
    
                }
                
                Spacer()
                
                HStack {
                    
                    if cameraModel.isTaken {
                        Button {
                            if !cameraModel.isSaved { cameraModel.savePic() }
                        } label: {
                            Text(cameraModel.isSaved ? "Saved" : "Save")
                                .foregroundColor(.black)
                                .fontWeight(.semibold)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(Color.white)
                                .clipShape(Capsule())
                        }
                        .padding(.leading)
                        
                        Spacer()
                        
                    } else {
                        Button {
                            cameraModel.takePic()
                        } label: {
                            ZStack{
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 70, height: 70)
                            }
                        }
                    }
                }
                .frame(height:75)
            }
        }
        .onAppear {cameraModel.Check()}
    }
}


// cameraModel Model
class NewcameraModelModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    
    @Published var isTaken = false
    
    @Published var session = AVCaptureSession()
    
    @Published var alert = false
    
    // this cause pictures are data
    @Published var output = AVCapturePhotoOutput()
    
    // this the preview
    @Published var preview: AVCaptureVideoPreviewLayer!
    
    // picture data
    @Published var isSaved = false
    @Published var picData = Data(count: 0)
    
    func Check() {
        
        // check perms
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            
        case .authorized:
            setUp()
            return
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { (status) in
                if status {
                    self.setUp()
                }
            }
            
        case .denied:
            self.alert.toggle()
            return
            
        default:
            return
            
        }
        
    }
    
    func setUp() {
        
        do {
            self.session.beginConfiguration()
            
            // might need to alter for our needs
            let device = AVCaptureDevice.default(for: .video)
            
            // prob shouldnt force unwrap
            let input = try AVCaptureDeviceInput(device: device!)
            
            // check for input
            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            
            //check for output
            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }
            
            self.session.commitConfiguration()
        }
        catch {
            print(error.localizedDescription)
        }
        
    }
    
    func takePic() {
        DispatchQueue.global(qos:.background).async {
            
            self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
            
            DispatchQueue.main.async {
                withAnimation {self.isTaken.toggle()}
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
          self.session.stopRunning()
        }
        
        
    }
    
    func untakePic() {
        
        DispatchQueue.global(qos: .background).async {
            
            self.session.startRunning()
            
            DispatchQueue.main.async {
                withAnimation{self.isTaken.toggle()}
                self.isSaved = false
            }
            
        }
        
    }
    
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
        
        if error != nil {
            print("DEBUG: went out cause error")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("DEBUG: No image data")
            return
        }
        
        self.picData = imageData
    }
    
    func savePic() {
        
        // prob shouldnt force unwrap
        let image = UIImage(data: self.picData)!
        
        // saving image
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        self.isSaved = true
    }
    
}

// Set up for preview

struct NewcameraModelPreview: UIViewRepresentable {
    
    @ObservedObject var cameraModel: NewcameraModelModel
    
    func makeUIView(context: Context) -> UIView {
        
        let view = UIView(frame: UIScreen.main.bounds)
        
        cameraModel.preview = AVCaptureVideoPreviewLayer(session: cameraModel.session)
        cameraModel.preview.frame = view.frame
        
        // adjust to our own properties
        cameraModel.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(cameraModel.preview)
        
        cameraModel.session.startRunning()
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
    
}
