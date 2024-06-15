//
//  EditInstructionsView.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/8/24.
//

import SwiftUI

struct EditInstructionsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var titleInput: String = ""
    @State private var descriptionInput: String = ""
    @State private var isSaveButtonEnabled: Bool = false
    @State private var isTitleLimitReached: Bool = false
    @State private var isDescriptionLimitReached: Bool = false
    @ObservedObject var uploadViewModel: UploadViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Edit Instructions")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    HStack {
                        Text("(Max 10)")
                            .font(.caption)
                        Spacer()
                    }
                    ForEach(uploadViewModel.instructions.indices, id: \.self) { index in
                        let instruction = uploadViewModel.instructions[index]
                        VStack(alignment: .leading, spacing: 4) {
                            
                            HStack(spacing: 4) {
                                Button(action: {
                                    if let instructionIndex = uploadViewModel.instructions.firstIndex(of: instruction) {
                                        deleteInstruction(at: IndexSet(integer: instructionIndex))
                                    }
                                }) {
                                    Image(systemName: "xmark")
                                        .foregroundColor(Color("Colors/AccentColor"))
                                        .font(.headline)
                                        .padding()
                                }
                                InstructionBoxView(stepNumber: index + 1, title: instruction.title, description: instruction.description)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteInstruction)
                    if uploadViewModel.instructions.count >= 10 {
                        Text("Maximum instructions reached")
                            .foregroundColor(.red)
                            .bold()
                            .padding()
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            VStack(alignment: .leading) {
                                Text("Step \(uploadViewModel.instructions.count + 1)")
                                    .font(.headline)
                                    .padding(.top)
                                TextField("Instruction Title", text: $titleInput)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: titleInput) { oldValue, newValue in
                                        if newValue.count >= 40 {
                                            titleInput = String(newValue.prefix(40))
                                            isTitleLimitReached = true
                                        } else {
                                            isTitleLimitReached = false
                                        }
                                        updateSaveButtonState()
                                    }
                                HStack {
                                    if isTitleLimitReached {
                                        Text("Max characters reached")
                                            .foregroundColor(.red)
                                            .font(.caption)
                                    }
                                           Spacer()
                                           Text("\(titleInput.count)/40")
                                               .foregroundColor(.gray)
                                               .font(.caption)
                                       }
                                
                            }
                            VStack(alignment: .leading) {
                                ZStack(alignment: .topLeading) {
                                    TextEditor(text: $descriptionInput)
                                        .frame(height: 100)
                                        .border(Color.gray.opacity(0.2), width: 1)
                                        .onChange(of: descriptionInput) { oldValue, newValue in
                                            if newValue.count >= 150 {
                                                descriptionInput = String(newValue.prefix(150))
                                                isDescriptionLimitReached = true
                                            } else {
                                                isDescriptionLimitReached = false
                                            }
                                            updateSaveButtonState()
                                        }
                                    if descriptionInput.isEmpty {
                                        Text("Description")
                                            .foregroundColor(Color.gray.opacity(0.5))
                                            .padding(.top, 8)
                                            .padding(.leading, 5)
                                    }
                                }
                                HStack {
                                    if isDescriptionLimitReached {
                                        Text("Max characters reached")
                                            .foregroundColor(.red)
                                            .font(.caption)
                                    }
                                          Spacer()
                                          Text("\(descriptionInput.count)/150")
                                              .foregroundColor(.gray)
                                              .font(.caption)
                                      }
                               
                            }
                            HStack{
                                Button(action: saveInstruction) {
                                    Image(systemName: "plus")
                                        .padding()
                                        .foregroundColor(.white)
                                        .background(isSaveButtonEnabled ? Color("Colors/AccentColor") : Color.gray)
                                        .cornerRadius(8)
                                }
                                
                                
                                .disabled(!isSaveButtonEnabled)
                                Spacer()
                            }
                        }
                        .padding(.vertical)
                    }
                    
                   
                }
                .padding()
            }
            .modifier(BackButtonModifier())
        }
    }

    private func saveInstruction() {
        if uploadViewModel.instructions.count < 10 {
            let instruction = Instruction(title: titleInput, description: descriptionInput)
            uploadViewModel.instructions.append(instruction)

            titleInput = ""
            descriptionInput = ""
            updateSaveButtonState()
        }
    }

    private func deleteInstruction(at offsets: IndexSet) {
        uploadViewModel.instructions.remove(atOffsets: offsets)
        updateSaveButtonState()
    }

    private func updateSaveButtonState() {
        isSaveButtonEnabled = !titleInput.isEmpty && !descriptionInput.isEmpty && uploadViewModel.instructions.count < 10
    }
}

#Preview {
    EditInstructionsView(uploadViewModel: UploadViewModel())
}

