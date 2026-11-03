import SwiftUI
import UIKit

/// Lets the caller invoke the crop from SwiftUI once the user is happy.
final class CropController: ObservableObject {
    var crop: (() -> UIImage?)?
}

/// An Instagram/Facebook-style "Move and Scale" editor: pinch to zoom, drag to
/// reposition, inside a fixed crop aperture (a circle for photos, a rectangle
/// for logos). Returns the cropped image — never a stretched one.
struct ImageCropperView: View {
    let image: UIImage
    var aspect: CGFloat = 1          // aperture width / height
    var circle: Bool = true
    var title: String = "Move and Scale"
    var onDone: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var controller = CropController()

    private var normalized: UIImage { image.normalizedUp() }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let apertureW = min(geo.size.width - 40, 340)
                let apertureH = apertureW / aspect
                ZStack {
                    Color.black.ignoresSafeArea()
                    ZoomableImageView(image: normalized,
                                      apertureSize: CGSize(width: apertureW, height: apertureH),
                                      controller: controller)
                        .frame(width: apertureW, height: apertureH)
                        .clipShape(aperture(apertureH))
                        .overlay(aperture(apertureH).strokeBorder(.white.opacity(0.8), lineWidth: 2))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.tint(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Use") {
                        if let cropped = controller.crop?() { onDone(cropped) }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(.white)
                }
            }
        }
    }

    private func aperture(_ h: CGFloat) -> AnyShape {
        circle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// UIScrollView-backed zoom/pan with pixel-accurate cropping.
private struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage
    let apertureSize: CGSize
    let controller: CropController

    func makeCoordinator() -> Coordinator { Coordinator(image: image) }

    func makeUIView(context: Context) -> UIScrollView {
        let scroll = UIScrollView()
        scroll.delegate = context.coordinator
        scroll.showsVerticalScrollIndicator = false
        scroll.showsHorizontalScrollIndicator = false
        scroll.alwaysBounceVertical = true
        scroll.alwaysBounceHorizontal = true
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.backgroundColor = .clear

        let imageView = UIImageView(image: image)
        imageView.frame = CGRect(origin: .zero, size: image.size)
        scroll.addSubview(imageView)
        scroll.contentSize = image.size

        context.coordinator.scroll = scroll
        context.coordinator.imageView = imageView
        controller.crop = { [weak c = context.coordinator] in c?.croppedImage() }
        return scroll
    }

    func updateUIView(_ scroll: UIScrollView, context: Context) {
        context.coordinator.apertureSize = apertureSize
        DispatchQueue.main.async { context.coordinator.configureIfNeeded() }
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        let image: UIImage
        weak var scroll: UIScrollView?
        weak var imageView: UIImageView?
        var apertureSize: CGSize = .zero
        private var configured = false

        init(image: UIImage) { self.image = image }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

        func configureIfNeeded() {
            guard let scroll, apertureSize.width > 0, image.size.width > 0 else { return }
            let minScale = max(apertureSize.width / image.size.width,
                               apertureSize.height / image.size.height)
            scroll.minimumZoomScale = minScale
            scroll.maximumZoomScale = minScale * 5
            if !configured {
                scroll.zoomScale = minScale
                let x = max(0, (scroll.contentSize.width - scroll.bounds.width) / 2)
                let y = max(0, (scroll.contentSize.height - scroll.bounds.height) / 2)
                scroll.setContentOffset(CGPoint(x: x, y: y), animated: false)
                configured = true
            }
        }

        func croppedImage() -> UIImage? {
            guard let scroll, let cg = image.cgImage, scroll.zoomScale > 0 else { return nil }
            let zoom = scroll.zoomScale
            let rect = CGRect(x: scroll.contentOffset.x / zoom,
                              y: scroll.contentOffset.y / zoom,
                              width: scroll.bounds.width / zoom,
                              height: scroll.bounds.height / zoom)
            let px = image.scale
            var pxRect = CGRect(x: rect.minX * px, y: rect.minY * px,
                                width: rect.width * px, height: rect.height * px)
            pxRect = pxRect.intersection(CGRect(x: 0, y: 0, width: CGFloat(cg.width), height: CGFloat(cg.height)))
            guard pxRect.width > 1, pxRect.height > 1, let cropped = cg.cropping(to: pxRect) else { return nil }
            return UIImage(cgImage: cropped, scale: px, orientation: .up)
        }
    }
}

extension UIImage {
    /// Redraws the image upright so pixel cropping isn't affected by EXIF
    /// orientation.
    func normalizedUp() -> UIImage {
        if imageOrientation == .up { return self }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
