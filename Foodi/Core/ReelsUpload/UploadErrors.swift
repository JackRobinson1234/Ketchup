//
//  UploadErrors.swift
//  Foodi
//
//  Created by Joe Ciminelli on 4/23/24.
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


