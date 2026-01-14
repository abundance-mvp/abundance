import Foundation

#if os(iOS)
import UIKit
/// Platform-agnostic image type (UIImage on iOS)
public typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
/// Platform-agnostic image type (NSImage on macOS)
public typealias PlatformImage = NSImage
#endif
