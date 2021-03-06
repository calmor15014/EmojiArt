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
    
    @State private var chosenPalette: String = ""
    
    // To demonstrate how property wrapper is working, this init sets the value inside the @State
    // so that we don't need to use .onAppear.  Not the most elegant way to do it, but educational
    init(document: EmojiArtDocument) {
        self.document = document
        _chosenPalette = State(wrappedValue: self.document.defaultPalette)
    }
    
    var body: some View {
        VStack {
            HStack {
                PaletteChooser(document: document, chosenPalette: $chosenPalette)
                ScrollView(.horizontal) {
                    HStack {
                        // .map and id \.self info in OneNote
                        ForEach(chosenPalette.map { String($0) }, id: \.self) { emoji in
                            Text(emoji)
                                .font(Font.system(size: defaultEmojiSize))
                                .onDrag { NSItemProvider(object: emoji as NSString) }  // will cover "as" later
                        }
                    }
                }.onAppear { chosenPalette = document.defaultPalette }
            }
            GeometryReader{ geometry in
                ZStack{
                    // Background white (or image) view
                    Color.white.overlay( // overlay is for sizing purposes
                        OptionalImage(uiImage: document.backgroundImage)
                            .scaleEffect(zoomScale)
                            .offset(panOffset)
                    )
                    .gesture(doubleTapToZoom(in: geometry.size))
                    // Homework 4 Required Task 10 trashcan for deleting emoji
                    TrashCanView(size: trashCanAreaSize, dragIntoTrashArea: movedIntoTrashArea(in: geometry.size))
                        .position(showTrashCan ? CGPoint(x: 50, y: geometry.size.height - 50) : CGPoint(x: -100, y: geometry.size.height - 50))
                    // List of the emojis
                    if isLoading {
                        Image(systemName: "hourglass").imageScale(.large).spinning()
                    } else {
                        ForEach(document.emojis) { emoji in
                            Text(emoji.text)
                                .font(animatableWithSize: selectedEmoji.contains(matching: emoji) ? emoji.fontSize * selectionZoomScale : emoji.fontSize * zoomScale)
                                .border(selectedEmoji.contains(matching: emoji) ? Color.black : Color.clear)  // Homework 4 Required Task 2
                                .position(self.position(for: emoji, in: geometry.size))
                                .gesture(emojiSelect(emoji: emoji, in: geometry.size)) // Homework 4 Required Task 3, 4
                                .gesture(emojiMove(emoji: emoji, in: geometry.size)) // Homework 4 Required Task 6
                        }
                    }
                }.clipped()
                .gesture(clearSelections())  // Homework 4 Required Task 5
                .gesture(panGesture())
                .gesture(zoomGesture())
                .edgesIgnoringSafeArea([.horizontal, .bottom])
                .onReceive(document.$backgroundImage) { image in
                    zoomToFit(image, in: geometry.size)
                }
                .onDrop(of: ["public.image","public.text"], isTargeted: nil) { providers, location in
                    var location = geometry.convert(location, from: .global)
                    location = CGPoint(x: location.x - geometry.size.width / 2, y: location.y - geometry.size.height / 2)
                    location = CGPoint(x: location.x - self.panOffset.width, y: location.y - panOffset.height)
                    location = CGPoint(x: location.x / zoomScale, y: location.y / zoomScale)
                    return self.drop(providers: providers, at: location)
                }
                .navigationBarItems(trailing: Button( action: {
                    if let url = UIPasteboard.general.url, url != self.document.backgroundURL {     // shared clipboard
                        confirmBackgroundPaste = true
                    } else {
                        explainBackgroundPaste = true
                    }
                }, label: {
                    Image(systemName: "doc.on.clipboard").imageScale(.large)
                        .alert(isPresented: $explainBackgroundPaste) {
                            return Alert(title: Text("Paste Background"), message: Text("Copy the URL of an image to the clipboard and touch this button to make it the background of your document."), dismissButton: .default(Text("OK"))
                            )
                        }
                }))
            }
            .zIndex(-1) // also fixes the errors
        }.ignoresSafeArea(.keyboard) // required to keep emojis from shifting up for whatever reason...
        // Just thrown here to avoid putting two things on the same image.  Would be better to enum and switch on the above.
        .alert(isPresented: $confirmBackgroundPaste) {
            Alert(
                title: Text("Paste Background"),
                message: Text("Replace your background with \(UIPasteboard.general.url?.absoluteString ?? "nothing")?"),
                primaryButton: .default(Text("OK")) {
                    document.backgroundURL = UIPasteboard.general.url
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // Would be better to put this as an enum most likely... since can't have two alert(isPresented) on the same view.
    @State private var explainBackgroundPaste = false
    @State private var confirmBackgroundPaste = false
    
    var isLoading: Bool {
        document.backgroundURL != nil && document.backgroundImage == nil
    }
    
    // MARK: - Moving / Deleting Emoji
    
    @State private var movingEmojiTouched: Int? = nil
    @GestureState private var gestureMoveLocation: CGPoint = .zero
    @GestureState private var gestureMoveOffset: CGSize = .zero
    
    private var showTrashCan: Bool {
        return movingEmojiTouched != nil
    }
    
    private var movingEmojiInSelection: Bool {
        guard let touchedID = movingEmojiTouched else { return false }
        return selectedEmoji.contains(where: {$0.id == touchedID})
    }
    
    private func movedIntoTrashArea(in geometry: CGSize) -> Bool {
        return gestureMoveLocation.x < 90 && gestureMoveLocation.y > geometry.height - 90
    }
    
    private var moveOffset: CGSize {
        gestureMoveOffset * zoomScale
    }
    
    private func emojiMove(emoji: EmojiArt.Emoji, in geometry: CGSize) -> some Gesture {
        DragGesture()
            .onChanged {_ in withAnimation(.easeInOut) { movingEmojiTouched = emoji.id }}
            .updating($gestureMoveLocation) { latestDragGestureValue, gestureMoveLocation, transaction in
                gestureMoveLocation = latestDragGestureValue.location
            }
            .updating($gestureMoveOffset) { latestDragGestureValue, gestureMoveOffset, transaction in
                gestureMoveOffset = latestDragGestureValue.translation / zoomScale  // this is NOT the @GestureState var... its local inout
                //print(latestDragGestureValue.location)
            }
            .onEnded { finalDragGestureValue in
                if finalDragGestureValue.location.x < 90 && finalDragGestureValue.location.y > geometry.height - 90 {
                    deleteDrop(touchedEmoji: emoji)
                } else {
                    moveEmojis(by: finalDragGestureValue.translation / zoomScale, touchedEmoji: emoji)
                }
                withAnimation(.easeInOut) { movingEmojiTouched = nil }
            }
    }
    
    private func moveEmojis(by offset: CGSize, touchedEmoji: EmojiArt.Emoji) {
        if selectedEmoji.contains(matching: touchedEmoji) {
            for emoji in selectedEmoji {
                document.moveEmoji(emoji, by: offset)
            }
        } else {
            document.moveEmoji(touchedEmoji, by: offset)
        }
    }
    
    private func deleteDrop(touchedEmoji: EmojiArt.Emoji) {
        if selectedEmoji.contains(matching: touchedEmoji) {
            for emoji in selectedEmoji {
                document.removeEmoji(emoji)
            }
        } else {
            document.removeEmoji(touchedEmoji)
        }
    }
    
    // MARK: - Clear Selections
    
    // Single-tap on the background image clears the selections
    // Homework 4 Required Task 5
    private func clearSelections() -> some Gesture {
        TapGesture().onEnded { selectedEmoji = [] }
    }
    
    // MARK: - Emoji Selection/De-selection
    
    // Single-tap on the emoji selects it or deselects it
    // Homework 4 Required Tasks 2, 3, 4
    private func emojiSelect(emoji: EmojiArt.Emoji, in geometry: CGSize) -> some Gesture {
        TapGesture()
            .onEnded {
                selectedEmoji.toggleMatching(emoji)
            }.exclusively(before: emojiMove(emoji: emoji, in: geometry))
    }
    
    // MARK: - Scale Document/Emoji Gesture
    
    // UI-only, so @State.  We zoom emojis with the zoomscale too, so it doesn't go to the model
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    
    private var zoomScale: CGFloat {
        // zoomScale is used for all items when there is no selection
        // Homework 4 Required Task 8, 9
        if selectedEmoji.count == 0 {
            return document.steadyStateZoomScale * gestureZoomScale
        } else {
            return document.steadyStateZoomScale
        }
    }
    
    private var selectionZoomScale: CGFloat {
        document.steadyStateZoomScale * gestureZoomScale
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transaction in
                gestureZoomScale = latestGestureScale  // this is NOT the @GestureState var... its local inout
            }
            .onEnded { finalGestureScale in
                // Homework 4 Required Task 8, 9
                if selectedEmoji.count == 0 {
                    self.document.steadyStateZoomScale *= finalGestureScale
                } else {
                    scaleSelectedEmojis(by: finalGestureScale)
                }
            }
    }
    
    // Homework 4 Required Task 8
    private func scaleSelectedEmojis(by scale: CGFloat) {
        for emoji in selectedEmoji {
            document.scaleEmoji(emoji, by: scale)
        }
    }
    
    // MARK: - Pan Document
    
    @GestureState private var gesturePanOffset: CGSize = .zero
    
    private var panOffset: CGSize {
        // When pinch gesture is not in action, gestureZoomScale is 1.0 so no effect
        // and then no need to udpate it
        (document.steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, transaction in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale  // this is NOT the @GestureState var... its local inout
            }
            .onEnded { finalDragGestureValue in
                document.steadyStatePanOffset = document.steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
        }
    }

    // MARK: - Zoom Document to Fit Gesture
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2).onEnded {
            withAnimation {
                zoomToFit(document.backgroundImage, in: size)
            }
        }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        // New swift didn't need size.height
        if let image = image, image.size.width > 0, image.size.height > 0, size.height > 0, size.width > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            document.steadyStatePanOffset = .zero
            document.steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    // MARK: - Position and Drop Functions
    
    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: location.x + size.width/2, y: location.y + size.height/2)
        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
        // If an emoji is moving and it's in the selection
        if (movingEmojiInSelection) {
            // Move all of the emojis in the selection
            if selectedEmoji.contains(matching: emoji) {
                location = CGPoint(x: location.x + moveOffset.width, y: location.y + moveOffset.height)
            }
        // Or if an emoji is moving on its own, just move that one
        } else if movingEmojiTouched != nil && emoji.id == movingEmojiTouched {
            location = CGPoint(x: location.x + moveOffset.width, y: location.y + moveOffset.height)
        }
        return location
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            // print("dropped \(url)")
            self.document.backgroundURL = url
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                self.document.addEmoji(string, at: location, size: self.defaultEmojiSize)
            }
        }
        return found
    }
    
    // MARK: - Drawing Constants
    
    private let defaultEmojiSize: CGFloat = 40
    private let trashCanAreaSize: CGSize = CGSize(width: 100, height: 100)
}

// Turned off for now...
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
