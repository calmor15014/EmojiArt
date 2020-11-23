//
//  ContentView.swift
//  EmojiArt
//
//  Created by James Spece on 11/15/20.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    @State var selectedEmoji: Set<EmojiArt.Emoji> = []
    
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack {
                    // .map and id \.self info in OneNote
                    ForEach(EmojiArtDocument.palette.map { String($0) }, id: \.self) { emoji in
                        Text(emoji)
                            .font(Font.system(size: defaultEmojiSize))
                            .onDrag { NSItemProvider(object: emoji as NSString) }  // will cover "as" later
                    }
                }
            }
            .padding(.horizontal)
            GeometryReader{ geometry in
                ZStack{
                    Color.white.overlay( // overlay is for sizing purposes
                        OptionalImage(uiImage: document.backgroundImage)
                            .scaleEffect(zoomScale)
                            .offset(panOffset)
                    )
                    .gesture(doubleTapToZoom(in: geometry.size))
                    ForEach(document.emojis) { emoji in
                        Text(emoji.text)
                            .font(animatableWithSize: emoji.fontSize * zoomScale)
                            .border(selectedEmoji.contains(emoji) ? Color.black : Color.clear)  // Homework 4 Required Task 2
                            .position(self.position(for: emoji, in: geometry.size))
                            .gesture(emojiSelect(emoji: emoji)) // Homework 4 Required Task 3, 4
                    }
                }.clipped()
                .gesture(clearSelections())  // Homework 4 Required Task 5
                .gesture(panGesture())
                .gesture(zoomGesture())
                .edgesIgnoringSafeArea([.horizontal, .bottom])
                .onDrop(of: ["public.image","public.text"], isTargeted: nil) { providers, location in
                    var location = geometry.convert(location, from: .global)
                    location = CGPoint(x: location.x - geometry.size.width / 2, y: location.y - geometry.size.height / 2)
                    location = CGPoint(x: location.x - self.panOffset.width, y: location.y - panOffset.height)
                    location = CGPoint(x: location.x / zoomScale, y: location.y / zoomScale)
                    return self.drop(providers: providers, at: location)
                } // of is a URI, location is in global coordinate space (entire device)
            }
        }
    }
    
    // Single-tap on the background image clears the selections
    // Homework 4 Required Task 5
    private func clearSelections() -> some Gesture {
        TapGesture().onEnded { selectedEmoji = [] }
    }
    
    // Single-tap on the emoji selects it or deselects it
    // Homework 4 Required Tasks 2, 3, 4
    private func emojiSelect(emoji: EmojiArt.Emoji) -> some Gesture {
        TapGesture()
            .onEnded {
                selectedEmoji.toggleMatching(emoji)
            }.exclusively(before: zoomGesture())
    }
    
    // UI-only, so @State.  We zoom emojis with the zoomscale too, so it doesn't go to the model
    @State private var steadyStateZoomScale: CGFloat = 1.0
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    
    private var zoomScale: CGFloat {
        // When pinch gesture is not in action, gestureZoomScale is 1.0 so no effect
        // and then no need to udpate it
        steadyStateZoomScale * gestureZoomScale
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transaction in
                gestureZoomScale = latestGestureScale  // this is NOT the @GestureState var... its local inout
            }
            .onEnded { finalGestureScale in
            self.steadyStateZoomScale *= finalGestureScale
        }
    }
    
    @State private var steadyStatePanOffset: CGSize = .zero
    @GestureState private var gesturePanOffset: CGSize = .zero
    
    private var panOffset: CGSize {
        // When pinch gesture is not in action, gestureZoomScale is 1.0 so no effect
        // and then no need to udpate it
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, transaction in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale  // this is NOT the @GestureState var... its local inout
            }
            .onEnded { finalDragGestureValue in
                steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
        }
    }
    
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2).onEnded {
            withAnimation {
                zoomToFit(document.backgroundImage, in: size)
            }
        }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            steadyStatePanOffset = .zero
            steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: location.x + size.width/2, y: location.y + size.height/2)
        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
        return location
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            // print("dropped \(url)")
            self.document.setBackgroundURL(url)
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                self.document.addEmoji(string, at: location, size: self.defaultEmojiSize)
            }
        }
        return found
    }
    
    private let defaultEmojiSize: CGFloat = 40
}

// Turned off for now...
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}