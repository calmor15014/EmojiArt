//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by James Spece on 11/28/20.
//

import SwiftUI

struct PaletteChooser: View {
    @ObservedObject var document: EmojiArtDocument
    
    // @State vars are almost always private, but binding rarely is
    @Binding var chosenPalette: String
    @State private var showPaletteEditor = false
    
    var body: some View {
        HStack {
            Stepper(
                onIncrement: { chosenPalette = document.palette(after: chosenPalette)},
                onDecrement: { chosenPalette = document.palette(before: chosenPalette)},
                label: {
                    EmptyView()
                })
            Text(document.paletteNames[self.chosenPalette] ?? "")
            Image(systemName: "keyboard").imageScale(.large)
                .onTapGesture { showPaletteEditor = true }
                .popover(isPresented: $showPaletteEditor) {
                    PaletteEditor(chosenPalette: $chosenPalette, isShowing: $showPaletteEditor)
                        .environmentObject(document)
                        .frame(minWidth: 300, minHeight: 500)
                }
            // sheet could be used vs. popover
        }.fixedSize(horizontal: true, vertical: false) // uses just the space it needs
    }
}

struct PaletteEditor: View {
    @EnvironmentObject var document: EmojiArtDocument
    
    @Binding var chosenPalette: String
    @Binding var isShowing: Bool
    @State private var paletteName: String = ""
    @State private var emojisToAdd: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Palette Editor").font(.headline).padding()
                HStack {
                    Spacer()
                    Button(action: {
                        isShowing = false
                    }, label: { Text("Done") }).padding()
                }
            }
            Form {
                Section {
                    TextField("Palette Name", text: $paletteName, onEditingChanged : { began in
                        if !began {
                            document.renamePalette(chosenPalette, to: paletteName)
                        }
                    })
                    TextField("Add Emoji", text: $emojisToAdd, onEditingChanged : { began in
                        if !began {
                            chosenPalette = document.addEmoji(emojisToAdd, toPalette: chosenPalette)
                            emojisToAdd = ""
                        }
                    })
                }
                Section(header: Text("Remove Emoji")) {
                    Grid(chosenPalette.map { String($0) }, id: \.self) { emoji in
                        Text(emoji).font(Font.system(size: fontSize))
                            .onTapGesture {
                                self.chosenPalette = self.document.removeEmoji(emoji, fromPalette: chosenPalette)
                            }
                    }.frame(height: height)
                }
            }
        }
        .onAppear { paletteName = document.paletteNames[self.chosenPalette] ?? "" }
    }
    
    // MARK: - Drawing Constants
    
    var height: CGFloat {
        CGFloat((chosenPalette.count - 1) / 6) * 70 + 70
    }
    let fontSize: CGFloat = 40
    
}

struct PaletteChooser_Previews: PreviewProvider {
    static var previews: some View {
        PaletteChooser(document: EmojiArtDocument(), chosenPalette: Binding.constant(""))
    }
}
