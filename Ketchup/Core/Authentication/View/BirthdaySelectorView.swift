//
//  BirthdaySelectorView.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/14/24.
//
import SwiftUI
struct BirthdaySelectorView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedBirthday: Date?
    @State private var tempBirthday: Date = Date()
    @State private var navigateToLocationSelection = false
    @State private var showAgeRestrictionAlert = false
    @ObservedObject var registrationViewModel: UserRegistrationViewModel

    private let minimumAge: Int = 13

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image("KetchupTextRed")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
            
            Text("Select Your Birthday")
                .font(.custom("MuseoSansRounded-700", size: 26))
                .foregroundColor(.black)
            
            Text("You must be at least \(minimumAge) years old to use this app.")
                .font(.custom("MuseoSansRounded-500", size: 14))
                .foregroundColor(.gray)
            
            DatePicker("", selection: $tempBirthday, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(WheelDatePickerStyle())
                .frame(maxHeight: 400)
            
            Spacer()
            
            Button(action: {
                if isUserOldEnough(birthday: tempBirthday) {
                    selectedBirthday = tempBirthday
                    navigateToLocationSelection = true
                } else {
                    showAgeRestrictionAlert = true
                }
            }) {
                Text("Continue")
                    .font(.custom("MuseoSansRounded-500", size: 20))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("Colors/AccentColor"))
                    .cornerRadius(25)
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToLocationSelection) {
            LocationSelectionView(selectedLocation: .constant(nil), registrationViewModel: registrationViewModel)
        }
        .alert(isPresented: $showAgeRestrictionAlert) {
            Alert(
                title: Text("Age Restriction"),
                message: Text("You must be at least \(minimumAge) years old to use this app."),
                dismissButton: .default(Text("OK"))
            )
        }
        .onChange(of: tempBirthday) { newValue in
            registrationViewModel.birthday = newValue
        }
        .navigationBarItems(leading: Button(action: { dismiss() }) {
            if let userSession = AuthService.shared.userSession, userSession.birthday == nil {
                   
                }
             else {
                Image(systemName: "chevron.left")
                    .foregroundColor(.black)
            }
        })
    }
    
    private func isUserOldEnough(birthday: Date) -> Bool {
        let today = Date()
        let calendar = Calendar.current
        let birthDateComponents = calendar.dateComponents([.year], from: birthday, to: today)
        return birthDateComponents.year! >= minimumAge
    }
}
