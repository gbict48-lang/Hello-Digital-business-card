import SwiftUI

/// Liquid-Glass helpers. On iOS 26+ these use the real `glassEffect` API; on
/// earlier systems they fall back to the closest system material so the app
/// still looks native and builds against older SDKs.
extension View {
    /// Applies a glass surface clipped to `shape`.
    ///
    /// The `#if compiler(>=6.2)` guard means the real Liquid-Glass API is only
    /// referenced when building with the Xcode 26 toolchain (which ships that
    /// SDK). Older toolchains compile the material fallback, so the project
    /// builds everywhere and still looks native.
    @ViewBuilder
    func glassSurface<S: Shape>(_ shape: S, interactive: Bool = false) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            self.glassEffect(interactive ? .regular.interactive() : .regular, in: shape)
        } else {
            self.materialSurface(shape)
        }
        #else
        self.materialSurface(shape)
        #endif
    }

    private func materialSurface<S: Shape>(_ shape: S) -> some View {
        // `stroke` (not `strokeBorder`) so this works for any `Shape`, not just
        // `InsettableShape`.
        self
            .background(.ultraThinMaterial, in: shape)
            .overlay(shape.stroke(Color.white.opacity(0.12), lineWidth: 0.5))
    }

    /// A rounded-rect glass card surface — the default building block.
    func glassCard(cornerRadius: CGFloat = 24, interactive: Bool = false) -> some View {
        glassSurface(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous),
                     interactive: interactive)
    }
}

/// A capsule button styled as an interactive glass pill — used for the main
/// actions (Share, Add to Wallet).
struct GlassButtonStyle: ButtonStyle {
    var tint: Color = .accentColor
    var prominent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .padding(.vertical, 14)
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity)
            .foregroundStyle(prominent ? Color.white : tint)
            .background {
                if prominent {
                    Capsule().fill(tint.gradient)
                } else {
                    Capsule().fill(.clear).glassSurface(Capsule(), interactive: true)
                }
            }
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
