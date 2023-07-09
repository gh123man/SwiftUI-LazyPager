//
//  ZoomableScrollView.swift
//  ImageScrollView
//
//  Created by Brian Floersch on 7/6/23.
//

import Foundation
import UIKit
import SwiftUI

public struct LazyPager<Content: View, DataType> {
    private var viewLoader: (DataType) -> Content
    private var data: [DataType]
    private var page: Binding<Int>
    
    var backgroundOpacity: Binding<CGFloat>?
    var dismissCallback: (() -> ())?
    var tapCallback: (() -> ())?
    
    public init(data: [DataType],
         page: Binding<Int>,
         content: @escaping (DataType) -> Content) {
        self.data = data
        self.page = page
        self.viewLoader = content
    }

    public class Coordinator: ViewDataProvider<Content, DataType> { }
}

public extension LazyPager {
    func onDismiss(backgroundOpacity: Binding<CGFloat>? = nil, _ callback: @escaping () -> ()) -> LazyPager {
        var this = self
        this.backgroundOpacity = backgroundOpacity
        this.dismissCallback = callback
        return this
    }
    
    func onTap(_ callback: @escaping () -> ()) -> LazyPager {
        var this = self
        this.tapCallback = callback
        return this
    }
}

extension LazyPager: UIViewRepresentable {
    public func makeUIView(context: Context) -> UIScrollView {
        DispatchQueue.main.async {
            context.coordinator.goToPage(page.wrappedValue)
        }
        return context.coordinator.scrollView
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(data: data,
                           page: page,
                           backgroundOpacity: backgroundOpacity,
                           dismissCallback: dismissCallback,
                           tapCallback: tapCallback,
                           viewLoader: viewLoader)
    }

    public func updateUIView(_ uiView: UIScrollView, context: Context) {}
}
