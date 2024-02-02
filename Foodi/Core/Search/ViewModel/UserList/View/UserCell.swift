//
//  UserCell.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI

struct UserCell: View {
    let user: User
    
    init(user: User) {
        self.user = user
    }
    
    var body: some View {
        HStack(spacing: 12) {
            UserCircularProfileImageView(user: user, size: .medium)
            
            VStack(alignment: .leading) {
                Text(user.username)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(user.fullname)
                    .font(.footnote)
            }
            .foregroundStyle(.black)
            
            Spacer()
            
//            Button {
//
//            } label: {
//                Text("Follow")
//                    .font(.system(size: 14, weight: .semibold))
//                    .frame(width: 88, height: 32)
//                    .foregroundColor(.white)
//                    .background(.pink)
//                    .cornerRadius(6)
//            }
        }
    }
}


#Preview {
    UserCell(user: DeveloperPreview.user)
}
