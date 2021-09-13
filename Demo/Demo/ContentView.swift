//
//  ContentView.swift
//  Demo
//
//  Created by An Tran on 14/9/21.
//

import SwiftUI
import AnPhotosPicker

struct ContentView: View {
    @State private var isPresentingImagePicker = false

    @State var selectedImages = [SelectedImage]()

    var body: some View {
        VStack {
            Button(
                action: {
                    isPresentingImagePicker.toggle()
                },
                label: {
                    Text("Present Photos Picker")
                }
            )

            ForEach(selectedImages, id: \.self) { selectedImage in
                Image(uiImage: selectedImage.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200, alignment: .leading)
            }
        }
        .sheet(isPresented: $isPresentingImagePicker) {
            AnPhotosPicker(
                filter: .images,
                selectionLimit: 4,
                completionHandler: { (images: [SelectedImage]) in
                    isPresentingImagePicker = false
                    self.selectedImages = images
                }
            )
        }

    }
}
