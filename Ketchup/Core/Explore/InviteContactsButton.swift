//
//  InviteContactsButton.swift
//  Ketchup
//
//  Created by Jack Robinson on 10/9/24.
//

import SwiftUI

struct InviteContactsButton: View {
    var body: some View {
        VStack {
            Divider()
            HStack {
                Image(systemName: "envelope")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30)
                    .foregroundStyle(.black)
                Text("Invite your friends to Beta!")
                    .font(.custom("MuseoSansRounded-700", size: 16))
                    .foregroundStyle(.black)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.gray)
                    .padding(.horizontal)
            }
            .padding(.horizontal)
            .padding(.vertical)
            Divider()
        }
    }
}
