//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by James Spece on 11/15/20.
//

import SwiftUI

class EmojiArtDocument: ObservableObject {
    
    // Static so that it is not specific to class instances
    // Eventually will be an array of palettes and be a var
    static let palette: String = "🍎😀😎🐵⚔️📍"
    
    // Don't need the workaround for @Published swift problems, now fixed in newest Swift
    @Published private var emojiArt: EmojiArt = EmojiArt() {
        didSet {
            // print("json = \(emojiArt.json?.utf8 ?? "nil")")  // testing only
            UserDefaults.standard.set(emojiArt.json, forKey: EmojiArtDocument.untitled)
        }
    }
    
    private static let untitled = "EmojiArtDocument.Untitled"
    
    init() {
        emojiArt = EmojiArt(json: UserDefaults.standard.data(forKey: EmojiArtDocument.untitled)) ?? EmojiArt()
        fetchBackgroundImageData()
    }
    
    // Published so that when it changes, the view redraws
    @Published private(set) var backgroundImage: UIImage?
    
    var emojis: [EmojiArt.Emoji] { emojiArt.emojis }
    
    // MARK: - Intent(s)
    
    func addEmoji(_ emoji: String, at location: CGPoint, size: CGFloat) {
        emojiArt.addEmoji(emoji, x: Int(location.x), y: Int(location.y), size: Int(size))
    }
    
    func moveEmoji(_ emoji: EmojiArt.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArt.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrEven))
        }
    }
    
    func setBackgroundURL(_ url: URL?) {
        emojiArt.backgroundURL = url?.imageURL
        fetchBackgroundImageData()
    }
    
    // This is the main part of this lecture
    private func fetchBackgroundImageData() {
        // Going to get a new image, so clear now (also shows there is some progress)
        backgroundImage = nil
        // Only fetch if there is an actual URL to look for
        if let url = self.emojiArt.backgroundURL {
            // Normally would use URLSession instead of this manual method
            // Will cover try? another time, but returns nil on failure
            // This would be code-blocking if on the main thread...
            DispatchQueue.global(qos: .userInitiated).async {
                if let imageData = try? Data(contentsOf: url) {
                    // But now we have to manage the UI on the main thread, so let's queue that code
                    DispatchQueue.main.async {
                        // Make sure user still wanted it i.e. slow image finally returned but
                        // user picked another while waiting for the old one
                        if url == self.emojiArt.backgroundURL {
                            self.backgroundImage = UIImage(data: imageData)
                        }
                    }
                }
            }
        }
    }
}

// Not violating MVVM, adding code in the ViewModel to keep CG and UI items in the model
// And the Ints aren't passed to the view
extension EmojiArt.Emoji {
    var fontSize: CGFloat { CGFloat(self.size) }
    var location: CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y))}
}
