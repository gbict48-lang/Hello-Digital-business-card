import SwiftUI
import PhotosUI

/// Wraps SwiftUI's `PhotosPicker`, then lets the user **move & scale** the
/// picked image in a crop editor before storing downsized PNG data.
struct PhotoPickerButton: View {
    @Binding var photoData: Data?
    var label: String = "Photo"
    var icon: String = "photo.on.rectangle.angled"
    /// Crop aperture aspect (width/height). 1 = square/circle (photo); wider for logos.
    var aspect: CGFloat = 1
    /// Show a circular aperture (photos) vs a rectangle (logos).
    var circle: Bool = true

    @State private var selection: PhotosPickerItem?
    @State private var picked: PickedImage?

    private struct PickedImage: Identifiable { let id = UUID(); let image: UIImage }

    var body: some View {
        PhotosPicker(selection: $selection, matching: .images, photoLibrary: .shared()) {
            Label(photoData == nil ? "Add \(label)" : "Change \(label)", systemImage: icon)
        }
        .onChange(of: selection) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run { picked = PickedImage(image: image) }
                }
                await MainActor.run { selection = nil }
            }
        }
        .sheet(item: $picked) { item in
            ImageCropperView(image: item.image, aspect: aspect, circle: circle,
                             title: circle ? "Move and Scale" : "Frame your logo") { cropped in
                photoData = cropped.downsizedPNG(maxDimension: circle ? 600 : 720)
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
