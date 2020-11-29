//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by James Spece on 11/15/20.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    // None of this was in the demo as it's still using AppDelegate
    // Guessed at its usage, seems to work fine!
    let store = EmojiArtDocumentStore(named: "Emoji Art")
    
    // Now that this is persistent in UserDefaults, it's no longer needed to add at start
//    init() {
//        store.addDocument()
//        store.addDocument(named: "Hello World")
//    }
    
    var body: some Scene {
        WindowGroup {
            //EmojiArtDocumentView(document: EmojiArtDocument())
            EmojiArtDocumentChooser().environmentObject(store)
        }
    }
}
