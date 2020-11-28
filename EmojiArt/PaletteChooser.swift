//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by James Spece on 11/28/20.
//

import SwiftUI

struct PaletteChooser: View {
    @ObservedObject var document: EmojiArtDocument
    
    // @State vars are almost always private
    @Binding var chosenPalette: String
    
    var body: some View {
        HStack {
            Stepper(
                onIncrement: { chosenPalette = document.palette(after: chosenPalette)},
                onDecrement: { chosenPalette = document.palette(before: chosenPalette)},
                label: {
                    EmptyView()
                })
            Text(document.paletteNames[self.chosenPalette] ?? "")
        }.fixedSize(horizontal: true, vertical: false) // uses just the space it needs
    }
}

struct PaletteChooser_Previews: PreviewProvider {
    static var previews: some View {
        PaletteChooser(document: EmojiArtDocument(), chosenPalette: Binding.constant(""))
    }
}
