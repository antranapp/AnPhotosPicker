//
// Copyright © 2021 An Tran. All rights reserved.
//

import AVFoundation
import Foundation
import UIKit

public struct SelectedImage: Equatable, Hashable {
    public let image: UIImage
}

public struct SelectedVideo: Equatable, Hashable {
    public let url: URL
    public let type: AVFileType
    public let previewImage: UIImage?
}
