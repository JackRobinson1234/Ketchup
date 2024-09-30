//
//  PollUploadView.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/28/24.
//

import SwiftUI
import PhotosUI
import FirebaseFirestoreInternal
import FirebaseStorage

struct PollUploadView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = PollUploadViewModel()
    @State private var isShowingImagePicker = false
    @State private var showPreview = false
    
    // State variables for delete alert
    @State private var showDeleteConfirmation = false
    @State private var pollToDelete: Poll?
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Display the number of consecutive scheduled polls
                        Text("Number of consecutive polls scheduled: \(viewModel.consecutiveScheduledPolls)")
                            .font(.subheadline)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        // Question Input
                        Text("Question")
                            .font(.headline)
                        TextField("Enter your question", text: $viewModel.question)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.bottom, 8)
                        
                        // Options Input
                        Text("Options")
                            .font(.headline)
                        ForEach(0..<viewModel.options.count, id: \.self) { index in
                            HStack {
                                TextField("Option \(index + 1)", text: $viewModel.options[index])
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                if viewModel.options.count > 2 {
                                    Button(action: {
                                        viewModel.options.remove(at: index)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                        if viewModel.options.count < 5 {
                            Button(action: {
                                viewModel.options.append("")
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.red)
                                    Text("Add Option")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        // Image Picker
                        Text("Image")
                            .font(.headline)
                        if let selectedImage = viewModel.selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .onTapGesture {
                                    isShowingImagePicker = true
                                }
                        } else {
                            Button(action: {
                                isShowingImagePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "photo")
                                        .foregroundColor(.red)
                                    Text("Select Image")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        // Calendar View
                        Text("Select a Date")
                            .font(.headline)
                        CalendarView(
                            selectedDate: $viewModel.selectedDate,
                            scheduledDates: viewModel.scheduledPolls.map { viewModel.startOfDayPST(for: $0.scheduledDate) },
                            pollsByDate: Dictionary(
                                uniqueKeysWithValues: viewModel.scheduledPolls.map { (viewModel.startOfDayPST(for: $0.scheduledDate), $0) }
                            ),
                            onDeletePoll: { poll in
                                self.pollToDelete = poll
                                self.showDeleteConfirmation = true
                            }
                        )
                        .padding(.vertical)
                        
                        // Warning if the selected date is already taken
                        if let selectedDate = viewModel.selectedDate {
                            if viewModel.scheduledPolls.contains(where: { viewModel.startOfDayPST(for: $0.scheduledDate) == viewModel.startOfDayPST(for: selectedDate) }) {
                                Text("A poll is already scheduled on the selected date.")
                                    .foregroundColor(.red)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding()
                }
                
                // Preview and Post Buttons
                HStack {
                    // Preview Button
                    Button(action: {
                        showPreview = true
                    }) {
                        Text("Preview Poll")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                    }
                    .sheet(isPresented: $showPreview) {
                        if let selectedDate = viewModel.selectedDate {
                            PollPreviewView(
                                question: viewModel.question,
                                options: viewModel.options,
                                selectedImage: viewModel.selectedImage,
                                scheduledDate: viewModel.startOfDayPST(for: selectedDate)
                            )
                        } else {
                            PollPreviewView(
                                question: viewModel.question,
                                options: viewModel.options,
                                selectedImage: viewModel.selectedImage,
                                scheduledDate: Date()
                            )
                        }
                    }
                    
                    // Post Button
                    Button(action: {
                        viewModel.uploadPoll {
                            dismiss()
                        }
                    }) {
                        if viewModel.isUploading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Schedule Poll")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(8)
                        }
                    }
                    .disabled(viewModel.isUploading)
                }
                .padding([.leading, .trailing, .bottom])
            }
            .navigationTitle("Create Poll")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
            .sheet(isPresented: $isShowingImagePicker) {
                PollImagePicker(image: $viewModel.selectedImage)
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Oops!"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
            // Delete confirmation alert
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Poll"),
                    message: Text("Are you sure you want to delete this poll?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let poll = self.pollToDelete {
                            viewModel.deletePoll(poll)
                        }
                        self.pollToDelete = nil
                    },
                    secondaryButton: .cancel {
                        self.pollToDelete = nil
                    }
                )
            }
        }
    }
    struct PollImagePicker: UIViewControllerRepresentable {
        @Binding var image: UIImage?
        
        func makeUIViewController(context: Context) -> some UIViewController {
            var configuration = PHPickerConfiguration()
            configuration.filter = .images // Only images
            configuration.selectionLimit = 1 // Single selection
            
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = context.coordinator
            
            return picker
        }
        
        func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
            // No updates needed
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        // Coordinator to handle picker results
        class Coordinator: NSObject, PHPickerViewControllerDelegate {
            let parent: PollImagePicker
            
            init(_ parent: PollImagePicker) {
                self.parent = parent
            }
            
            // Handle the selected image
            func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
                picker.dismiss(animated: true)
                
                guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
                    return
                }
                
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    if let uiImage = image as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.image = uiImage
                        }
                    }
                }
            }
        }
    }
}
