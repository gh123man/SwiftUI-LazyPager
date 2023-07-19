//
//  ClearFullScreenBackground.swift
//  
//
//  Created by Brian Floersch on 7/8/23.
//

import Foundation
import SwiftUI
import UIKit

public struct ClearFullScreenBackground: UIViewRepresentable {
    
    public init() { }
    
    public func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {}
}
