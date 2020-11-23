//
//  OptionalImage.swift
//  EmojiArt
//
//  Created by James Spece on 11/16/20.
//

import SwiftUI

struct OptionalImage: View {
    var uiImage: UIImage?
    
    var body: some View {
        if uiImage != nil {
            Image(uiImage: uiImage!)
        }
    }
}
