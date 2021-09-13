//
// Copyright © 2021 An Tran. All rights reserved.
//

import Foundation
import Photos
import PhotosUI
import SwiftUI
import UIKit

public struct AnPhotosPicker<T>: UIViewControllerRepresentable {
    
    public typealias UIViewControllerType = PHPickerViewController

    private let filter: PHPickerFilter
    private let selectionLimit: Int
    private let completionHandler: ([T]) -> Void
    
    public init(
        filter: PHPickerFilter = .images,
        selectionLimit: Int = 0,
        completionHandler: @escaping ([T]) -> Void
    ) {
        self.filter = filter
        self.selectionLimit = selectionLimit
        self.completionHandler = completionHandler
    }
    
    public func makeUIViewController(context: Context) -> PHPickerViewController {
        
        var configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        configuration.filter = filter
        configuration.selectionLimit = selectionLimit
        configuration.preferredAssetRepresentationMode = .current

        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
        
    }
    
    public func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(filter: filter, completionHandler: completionHandler)
    }
    
    public final class Coordinator: PHPickerViewControllerDelegate {
        
        // Use a serial queue to serialize async operations for the DispatchGroup
        private let queue = DispatchQueue(label: "app.antran.anphotospicker.queue")
        
        let completionHandler: ([T]) -> Void
        let filter: PHPickerFilter
        
        init(filter: PHPickerFilter, completionHandler: @escaping ([T]) -> Void) {
            self.filter = filter
            self.completionHandler = completionHandler
        }
        
        public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            let group = DispatchGroup()
            var selectedImages = [SelectedImage]()
            var selectedVideos = [SelectedVideo]()
            group.setTarget(queue: queue) // Explicitly assign a serial queue to ensure the operations are serialized
            for result in results {
                group.enter()
                if filter == .images {
                    getPhoto(from: result.itemProvider) { selectedImage in
                        if let selectedImage = selectedImage {
                            selectedImages.append(selectedImage)
                        }
                        group.leave()
                    }
                } else if filter == .videos {
                    getVideo(from: result.itemProvider, withIdentifier: result.assetIdentifier) { selectedVideo in
                        if let selectedVideo = selectedVideo {
                            selectedVideos.append(selectedVideo)
                        }
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                if self.filter == .images {
                    self.completionHandler(selectedImages as? [T] ?? [])
                } else if self.filter == .videos {
                    self.completionHandler(selectedVideos as? [T] ?? [])
                }
            }
        }
        
        private func getPhoto(from itemProvider: NSItemProvider, completionHandler: @escaping (SelectedImage?) -> Void) {
            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    guard error == nil else {
                        print(error!.localizedDescription)
                        completionHandler(nil)
                        return
                    }

                    guard let image = object as? UIImage else {
                        completionHandler(nil)
                        return
                    }

                    completionHandler(SelectedImage(image: image))
                }
            } else {
                completionHandler(nil)
            }
        }

        private func getVideo(
            from itemProvider: NSItemProvider,
            withIdentifier identifier: String?,
            completionHandler: @escaping (SelectedVideo?) -> Void
        ) {
            if itemProvider.hasItemConformingToTypeIdentifier(AVFileType.mp4.rawValue) {
                itemProvider.loadFileRepresentation(forTypeIdentifier: AVFileType.mp4.rawValue) { videoURL, error in

                    guard error == nil else {
                        print(error!.localizedDescription)
                        completionHandler(nil)
                        return
                    }

                    guard let videoURL = videoURL else {
                        completionHandler(nil)
                        return
                    }

                    guard let cachedURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent(videoURL.lastPathComponent) else {
                        completionHandler(nil)
                        return
                    }

                    do {
                        try? FileManager.default.removeItem(at: cachedURL)
                        try FileManager.default.copyItem(at: videoURL, to: cachedURL)
                    } catch {
                        print(error)
                        completionHandler(nil)
                        return
                    }

                    let previewImage = self.imageFromVideo(url: cachedURL, at: 0)

                    completionHandler(SelectedVideo(
                        url: cachedURL,
                        type: .mov,
                        previewImage: previewImage
                    ))
                }
            } else if itemProvider.hasItemConformingToTypeIdentifier(AVFileType.mov.rawValue) {
                itemProvider.loadFileRepresentation(forTypeIdentifier: AVFileType.mov.rawValue) { videoURL, error in

                    guard error == nil else {
                        print(error!.localizedDescription)
                        completionHandler(nil)
                        return
                    }

                    guard let videoURL = videoURL else {
                        completionHandler(nil)
                        return
                    }

                    guard let cachedURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent(videoURL.lastPathComponent) else {
                        completionHandler(nil)
                        return
                    }

                    do {
                        try? FileManager.default.removeItem(at: cachedURL)
                        try FileManager.default.copyItem(at: videoURL, to: cachedURL)
                    } catch {
                        print(error)
                        completionHandler(nil)
                        return
                    }

                    let previewImage = self.imageFromVideo(url: cachedURL, at: 0)

                    completionHandler(SelectedVideo(
                        url: videoURL,
                        type: .mp4,
                        previewImage: previewImage
                    ))
                }
            } else {
                completionHandler(nil)
            }
        }

        // https://stackoverflow.com/a/42521558/452115
        private func imageFromVideo(url: URL, at time: TimeInterval) -> UIImage? {
            let asset = AVURLAsset(url: url)
            let assetIG = AVAssetImageGenerator(asset: asset)
            assetIG.appliesPreferredTrackTransform = true
            assetIG.apertureMode = AVAssetImageGenerator.ApertureMode.encodedPixels

            let cmTime = CMTime(seconds: time, preferredTimescale: 60)
            let thumbnailImageRef: CGImage
            do {
                thumbnailImageRef = try assetIG.copyCGImage(at: cmTime, actualTime: nil)
            } catch {
                print("Error: \(error)")
                return nil
            }

            return UIImage(cgImage: thumbnailImageRef)
        }
    }
}
