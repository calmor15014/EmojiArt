//
//  EmojiArt.swift
//  EmojiArt
//
//  Created by James Spece on 11/15/20.
//

import Foundation

struct EmojiArt: Codable {
    var backgroundURL: URL?
    var emojis = [Emoji]()
    
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }
    
    // failable loading init
    init?(json: Data?) {
        if json != nil, let newEmojiArt = try? JSONDecoder().decode(EmojiArt.self, from: json!) {
            self = newEmojiArt
        } else {
            return nil
        }
    }
    
    // Replace the default init
    init() {}
    
    struct Emoji: Identifiable, Codable, Hashable {
        let text: String    // A let so that it doesn't change ever
        
        // 0,0 is middle of the coordinate system
        // Will need conversion for the view
        var x: Int
        var y: Int
        var size: Int
        
        // will be managed manually via EmojiArt
        let id: Int
        
        // Duplcate of the "default, free" init to
        // fileprivate Makes this private within the file, so nobody outside the file can create
        // new Emoji, but allows public setting of variables within an Emoji
        fileprivate init(text: String, x: Int, y: Int, size: Int, id: Int) {
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
        }
    }
    
    // MARK: - Emoji ID management
    private var uniqueEmojiId = 0
    
    mutating func addEmoji(_ text: String, x: Int, y: Int, size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(text: text, x: x, y: y, size: size, id: uniqueEmojiId))
    }
    
}
