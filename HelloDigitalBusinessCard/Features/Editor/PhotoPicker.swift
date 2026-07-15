import SwiftUI
import PhotosUI

/// Wraps SwiftUI's `PhotosPicker` and hands back downsized PNG data suitable
/// for embedding in a card / vCard / pass.
struct PhotoPickerButton: View {
    @Binding var photoData: Data?
    @State private var selection: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selection, matching: .images, photoLibrary: .shared()) {
            Label(photoData == nil ? "Add Photo" : "Change Photo", systemImage: "photo.on.rectangle.angled")
        }
        .onChange(of: selection) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    photoData = image.downsizedPNG(maxDimension: 512)
                }
            }
        }
    }
}

extension UIImage {
    /// Returns PNG data no larger than `maxDimension` on the longest side.
    func downsizedPNG(maxDimension: CGFloat) -> Data? {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return pngData() }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in draw(in: CGRect(origin: .zero, size: newSize)) }
        return resized.pngData()
    }
}
