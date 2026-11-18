import AppKit
import AmazingPetCore

struct WindowScan: Equatable {
    var world: World
    var maskRects: [CGRect]
}

enum WindowScanner {
    static func scan(overlay frame: NSRect, stage: Stage, pixel: CGFloat) -> WindowScan {
        let mainHeight = NSScreen.screens.first?.frame.height ?? frame.maxY
        let ownPID = ProcessInfo.processInfo.processIdentifier
        let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        var boxes: [Box] = []
        var rects: [CGRect] = []
        for info in windows {
            guard info[kCGWindowLayer as String] as? Int == 0,
                  info[kCGWindowOwnerPID as String] as? Int32 != ownPID,
                  (info[kCGWindowAlpha as String] as? Double ?? 1) > 0,
                  let bounds = (info[kCGWindowBounds as String] as? NSDictionary).flatMap({ CGRect(dictionaryRepresentation: $0) })
            else { continue }
            let rect = CGRect(x: bounds.minX - frame.minX, y: mainHeight - bounds.maxY - frame.minY, width: bounds.width, height: bounds.height)
            let box = Box(
                x: rect.minX / pixel, y: (frame.height - rect.maxY) / pixel,
                width: rect.width / pixel, height: rect.height / pixel
            )
            guard rect.intersects(CGRect(origin: .zero, size: frame.size)), World.isOccluder(box, on: stage) else { continue }
            boxes.append(box)
            rects.append(rect)
        }
        return WindowScan(world: World(occluders: boxes, cursor: cursor(in: frame, pixel: pixel)), maskRects: rects)
    }

    private static func cursor(in frame: NSRect, pixel: CGFloat) -> (x: Double, y: Double)? {
        let mouse = NSEvent.mouseLocation
        guard frame.contains(mouse) else { return nil }
        return ((mouse.x - frame.minX) / pixel, (frame.maxY - mouse.y) / pixel)
    }
}
