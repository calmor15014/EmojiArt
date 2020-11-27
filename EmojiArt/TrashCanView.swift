//
//  TrashCanView.swift
//  EmojiArt
//
//  Created by James Spece on 11/26/20.
//

import SwiftUI

struct TrashCanView: View {
    var size: CGSize
    var dragIntoTrashArea: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: trashCanBackgroundCornerRadius)
                .foregroundColor(.white)
                .opacity(trashCanBackgroundOpacity)
            Image(systemName: "trash")
                .font(Font.system(size: trashCanSize))
                .foregroundColor(dragIntoTrashArea ? .red : .black)
                
        }.frame(width: size.width, height: size.height)
    }
    
    // MARK: - Drawing Constants
    
    private let trashCanSize: CGFloat = 50
    private let trashCanBackgroundCornerRadius: CGFloat = 5.0
    private let trashCanBackgroundOpacity: Double = 0.75
}

//struct TrashCanView_Previews: PreviewProvider {
//    static var previews: some View {
//        TrashCanView()
//    }
//}
