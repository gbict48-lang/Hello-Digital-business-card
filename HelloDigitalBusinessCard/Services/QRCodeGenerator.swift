import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

/// Generates crisp QR codes from arbitrary strings (here: vCard payloads).
enum QRCodeGenerator {
    private static let context = CIContext()

    /// Produces a `UIImage` QR code.
    /// - Parameters:
    ///   - string: payload to encode.
    ///   - scale: pixel-multiplier for the base (small) CoreImage output.
    ///   - foreground / background: optional tinting. Keep high contrast so the
    ///     code stays scannable.
    static func image(
        from string: String,
        scale: CGFloat = 12,
        foreground: UIColor = .black,
        background: UIColor = .white
    ) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        // "H" = high error correction, so a logo/rounding won't break scanning.
        filter.correctionLevel = "H"

        guard var output = filter.outputImage else { return nil }
        output = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // Tint if custom colours were requested.
        if foreground != .black || background != .white {
            let colorFilter = CIFilter.falseColor()
            colorFilter.inputImage = output
            colorFilter.color0 = CIColor(color: foreground)
            colorFilter.color1 = CIColor(color: background)
            if let tinted = colorFilter.outputImage { output = tinted }
        }

        guard let cgImage = context.createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    /// Convenience: build a QR straight from a card's vCard.
    static func vCardImage(for card: BusinessCard) -> UIImage? {
        image(from: VCardBuilder.makeVCard(for: card, includePhoto: false))
    }
}

/// SwiftUI wrapper that renders a QR code and rebuilds it when the payload
/// changes.
struct QRCodeView: View {
    let payload: String
    var foreground: Color = .black
    var background: Color = .white

    var body: some View {
        if let image = QRCodeGenerator.image(
            from: payload,
            foreground: UIColor(foreground),
            background: UIColor(background)
        ) {
            Image(uiImage: image)
                .interpolation(.none)          // keep the pixels sharp
                .resizable()
                .scaledToFit()
                .accessibilityLabel("QR code containing contact details")
        } else {
            Image(systemName: "qrcode")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.secondary)
        }
    }
}
