# AnPhotosPicker

A package that wraps PHPickerViewController for SwiftUI

## Demo

https://user-images.githubusercontent.com/478757/133167187-4d3d1fed-eafb-45ac-ae6e-4792eea9a3de.mp4

## How to use

Take a look at the demo app

```swift
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
```

## License

MIT


