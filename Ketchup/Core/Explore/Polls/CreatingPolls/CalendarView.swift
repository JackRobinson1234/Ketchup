//
//  CalendarView.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/28/24.
//

import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date?
    let scheduledDates: [Date] // Dates with scheduled polls
    let pollsByDate: [Date: Poll] // Polls indexed by date
    let onDeletePoll: (Poll) -> Void

    var body: some View {
        VStack {
            DatePicker(
                "Select a Date",
                selection: Binding(
                    get: { selectedDate ?? Date() },
                    set: { newValue in
                        let today = startOfDayPST(for: Date())
                        let selectedDateStartOfDay = startOfDayPST(for: newValue)
                        if selectedDateStartOfDay >= today {
                            selectedDate = newValue
                        } else {
                            // Reset to today if a past date is selected
                            selectedDate = Date()
                        }
                    }
                ),
                in: Date()..., // Restrict selection to dates from today onwards
                displayedComponents: [.date]
            )
            .datePickerStyle(GraphicalDatePickerStyle())
            .padding()
            .environment(\.calendar, Calendar(identifier: .gregorian))
            .environment(\.locale, Locale(identifier: "en_US_POSIX"))
            .environment(\.timeZone, TimeZone(abbreviation: "PST")!)

            if let selectedDate = selectedDate,
               let scheduledPoll = pollsByDate[startOfDayPST(for: selectedDate)] {
                Text("Poll scheduled on this date:")
                    .font(.headline)
                PollPreviewView(
                    question: scheduledPoll.question,
                    options: scheduledPoll.options.map { $0.text },
                    selectedImage: nil,
                    scheduledDate: scheduledPoll.scheduledDate,
                    imageUrl: scheduledPoll.imageUrl
                )
                .padding()
                Button(action: {
                    onDeletePoll(scheduledPoll)
                }) {
                    Text("Delete Poll")
                        .foregroundColor(.red)
                }
                .padding()
            } else {
                Text("No poll scheduled on this date.")
                    .font(.subheadline)
                    .padding()
            }
        }
    }

    func startOfDayPST(for date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(abbreviation: "PST")!
        return calendar.startOfDay(for: date)
    }
}

struct PollPreviewView: View {
    let question: String
    let options: [String]
    let selectedImage: UIImage?
    let scheduledDate: Date
    var imageUrl: String? = nil

    var body: some View {
        VStack {
            let poll = Poll.createNewPoll(
                question: question,
                options: options.filter { !$0.isEmpty },
                imageUrl: imageUrl,
                scheduledDate: scheduledDate
            )

            PollView(
                poll: .constant(poll),
                selectedImage: selectedImage,
                isPreview: true, pollViewModel: PollViewModel()
            )
            .navigationTitle("Poll Preview")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
