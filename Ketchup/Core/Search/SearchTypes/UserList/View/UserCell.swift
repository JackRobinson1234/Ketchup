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
            UserCircularProfileImageView(profileImageUrl: user.profileImageUrl, size: .medium)
            
            VStack(alignment: .leading) {
                Text("@\(user.username)")
                    .font(.custom("MuseoSansRounded-300", size: 16))
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                Text(user.fullname)
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .foregroundStyle(.black)
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
