//
//  UploadError.swift
//  Foodi
//
//  Created by Jack Robinson on 5/5/24.
//

import Foundation
import SwiftUI

enum UploadError: Error {
    case videoUploadFailed
    case encodingFailed
    case thumbnailGenerationFailed
    case imageUploadFailed
    case userFetchFailed
    case unknownError
    case invalidMediaData
    case invalidMediaType
    case couldntMakeThumbnail
}
