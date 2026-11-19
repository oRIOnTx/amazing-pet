public enum WindowKind: Equatable {
    case code, music, chat, other

    private static let codeApps = [
        "com.apple.Terminal", "com.googlecode.iterm2", "dev.warp.Warp-Stable", "com.mitchellh.ghostty",
        "org.alacritty", "net.kovidgoyal.kitty", "com.github.wez.wezterm", "com.apple.dt.Xcode",
        "com.microsoft.VSCode", "com.microsoft.VSCodeInsiders", "com.todesktop.230313mzl4w4u92", "dev.zed.Zed",
        "com.sublimetext.4", "com.panic.Nova",
    ]
    private static let codePrefixes = ["com.jetbrains."]
    private static let musicApps = [
        "com.apple.Music", "com.spotify.client", "com.apple.podcasts", "com.tidal.desktop", "com.deezer.deezer-desktop",
    ]
    private static let chatApps = [
        "com.apple.MobileSMS", "ru.keepcoder.Telegram", "com.tdesktop.Telegram", "com.tinyspeck.slackmacgap",
        "com.hnc.Discord", "net.whatsapp.WhatsApp", "org.whispersystems.signal-desktop", "com.apple.mail",
        "com.readdle.smartemail-Mac", "com.viber.osx",
    ]

    public init(bundleID: String?) {
        guard let bundleID else {
            self = .other
            return
        }
        if Self.codeApps.contains(bundleID) || Self.codePrefixes.contains(where: bundleID.hasPrefix) {
            self = .code
        } else if Self.musicApps.contains(bundleID) {
            self = .music
        } else if Self.chatApps.contains(bundleID) {
            self = .chat
        } else {
            self = .other
        }
    }
}
