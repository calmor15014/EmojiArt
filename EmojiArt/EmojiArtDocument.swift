//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by James Spece on 11/15/20.
//

import SwiftUI
import Combine  // Needed for cancellable, subscribe, etc...

class EmojiArtDocument: ObservableObject, Hashable, Identifiable {
    
    let id: UUID
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)  // only works for classes; we'd have to do all variables for structs
    }
    
    static func == (lhs: EmojiArtDocument, rhs: EmojiArtDocument) -> Bool {
        lhs.id == rhs.id    // only works for classes because they're not copied on each pass
    }
    
    // Static so that it is not specific to class instances
    // Eventually will be an array of palettes and be a var
    static let palette: String = "🍎😀😎🐵⚔️📍"
    
    // Don't need the workaround for @Published swift problems, now fixed in newest Swift
    // But changed to follow Lecture 9 publisher.  Commented version worked in newest swift
    @Published private var emojiArt: EmojiArt //= EmojiArt() {
//        didSet {
//            // print("json = \(emojiArt.json?.utf8 ?? "nil")")  // testing only
//            UserDefaults.standard.set(emojiArt.json, forKey: EmojiArtDocument.untitled)
//        }
//    }
    
    // Added for cancellable and publishing events
    private var autosaveCancellable: AnyCancellable?
    
    init(id: UUID? = nil) {
        self.id = id ?? UUID()
        let defaultsKey = "EmojiArtDocument.\(self.id.uuidString)"
        emojiArt = EmojiArt(json: UserDefaults.standard.data(forKey: defaultsKey)) ?? EmojiArt()
        autosaveCancellable = $emojiArt.sink { emojiArt in
            //print("json = \(emojiArt.json?.utf8 ?? "nil")")  // testing only
            UserDefaults.standard.set(emojiArt.json, forKey: defaultsKey)
        }
        fetchBackgroundImageData()
    }
    
    // Published so that when it changes, the view redraws
    @Published private(set) var backgroundImage: UIImage?
    
    @Published var steadyStatePanOffset: CGSize = .zero
    @Published var steadyStateZoomScale: CGFloat = 1.0
    
    
    var emojis: [EmojiArt.Emoji] { emojiArt.emojis }
    
    // MARK: - Intent(s)
    
    func addEmoji(_ emoji: String, at location: CGPoint, size: CGFloat) {
        emojiArt.addEmoji(emoji, x: Int(location.x), y: Int(location.y), size: Int(size))
    }
    
    // Homework 4 Required Task 10
    func removeEmoji(_ emoji: EmojiArt.Emoji) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis.remove(at: index)
        }
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
    
    var backgroundURL: URL? {
        get {
            emojiArt.backgroundURL
        }
        set {
            emojiArt.backgroundURL = newValue?.imageURL
            fetchBackgroundImageData()
        }
    }
    
//    // This is the main part of the original EmojiArt lecture
//    // But now being replaced by URLSession
//    private func fetchBackgroundImageData() {
//        // Going to get a new image, so clear now (also shows there is some progress)
//        backgroundImage = nil
//        // Only fetch if there is an actual URL to look for
//        if let url = self.emojiArt.backgroundURL {
//            // Normally would use URLSession instead of this manual method
//            // Will cover try? another time, but returns nil on failure
//            // This would be code-blocking if on the main thread...
//            DispatchQueue.global(qos: .userInitiated).async {
//                if let imageData = try? Data(contentsOf: url) {
//                    // But now we have to manage the UI on the main thread, so let's queue that code
//                    DispatchQueue.main.async {
//                        // Make sure user still wanted it i.e. slow image finally returned but
//                        // user picked another while waiting for the old one
//                        if url == self.emojiArt.backgroundURL {
//                            self.backgroundImage = UIImage(data: imageData)
//                        }
//                    }
//                }
//            }
//        }
//    }
    
    private var fetchImageCancellable: AnyCancellable?               // Lives longer than the function to wait for network
    private func fetchBackgroundImageData() {
        // Going to get a new image, so clear for now (also indicates progress for new "loading" scheme
        backgroundImage = nil
        // Only fetch if there is an actual URL to look for
        if let url = emojiArt.backgroundURL {
            fetchImageCancellable?.cancel()                         // Cancel any older fetches that didn't complete
            fetchImageCancellable = URLSession.shared.dataTaskPublisher(for: url)     // default URLSession, done in a background thread
                .map { data, urlResponse in UIImage(data: data) }   // Now publisher returns a failable UIImage
                .receive(on: DispatchQueue.main)                    // Now publisher returns on the main queue
                .replaceError(with: nil)                            // Now publisher returns either UIImage or nil
                .assign(to: \.backgroundImage, on: self)            // assign only works if there is no error, this takes the place of .sink
                                                                    // \.backgroundImage is a keypath (weird?), \.backgroundImage as it's on self
        }
    }
}

// Not violating MVVM, adding code in the ViewModel to keep CG and UI items in the model
// And the Ints aren't passed to the view
extension EmojiArt.Emoji {
    var fontSize: CGFloat { CGFloat(self.size) }
    var location: CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y))}
}
