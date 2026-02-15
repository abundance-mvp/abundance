import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Platform-abstracted image decoding utilities.
///
/// Isolates UIKit/AppKit imports from SwiftUI View files per ADR-010.
/// Views should use these helpers instead of importing UIKit directly.
public enum ImageDecoding {

    /// Decode raw image data into a SwiftUI `Image`, or `nil` if data is invalid.
    public static func decodeToSwiftUIImage(_ data: Data) -> Image? {
        #if os(iOS)
        guard let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
        #elseif os(macOS)
        guard let nsImage = NSImage(data: data) else { return nil }
        return Image(nsImage: nsImage)
        #else
        return nil
        #endif
    }

    /// Decode raw image data and return the platform image size, or `nil` if invalid.
    public static func decodeWithSize(_ data: Data) -> (image: Image, size: CGSize)? {
        #if os(iOS)
        guard let uiImage = UIImage(data: data) else { return nil }
        return (Image(uiImage: uiImage), uiImage.size)
        #elseif os(macOS)
        guard let nsImage = NSImage(data: data) else { return nil }
        return (Image(nsImage: nsImage), nsImage.size)
        #else
        return nil
        #endif
    }
}
