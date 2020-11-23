//
//  AnimatableSystemFontModifier.swift
//  EmojiArt
//
//  Created by James Spece on 11/16/20.
//

import SwiftUI

struct AnimatableSystemFontModifer: AnimatableModifier {
    var size: CGFloat
    var weight: Font.Weight = .regular
    var design: Font.Design = .default
    
    func body(content: Content) -> some View {
        content.font(Font.system(size: size, weight: weight, design: design))
    }
    
    var animatableData: CGFloat {
        get { size }
        set { size = newValue }
    }
}

extension View {
    func font(animatableWithSize size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        self.modifier(AnimatableSystemFontModifer(size: size, weight: weight, design: design))
    }
}
