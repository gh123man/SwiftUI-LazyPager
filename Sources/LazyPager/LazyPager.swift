//
//  ZoomableScrollView.swift
//  ImageScrollView
//
//  Created by Brian Floersch on 7/6/23.
//

import Foundation
import UIKit
import SwiftUI

public extension LazyPager {
    func onDismiss(backgroundOpacity: Binding<CGFloat>? = nil, _ callback: @escaping () -> ()) -> LazyPager {
        return LazyPager(data: self.data,
                                  page: self.page,
                                  backgroundOpacity: backgroundOpacity,
                                  onDismiss: callback,
                                  content: self.viewLoader)
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
                           viewLoader: viewLoader)
    }

    public func updateUIView(_ uiView: UIScrollView, context: Context) {}
}


public struct LazyPager<Content: View, DataType> {
    private var viewLoader: (DataType) -> Content
    private var data: [DataType]
    private var page: Binding<Int>
    
    var backgroundOpacity: Binding<CGFloat>?
    var dismissCallback: (() -> ())?
    
    public init(data: [DataType],
         page: Binding<Int>,
         backgroundOpacity: Binding<CGFloat>? = nil,
         onDismiss: (() -> ())? = nil,
         content: @escaping (DataType) -> Content) {
        self.data = data
        self.page = page
        self.viewLoader = content
        self.backgroundOpacity = backgroundOpacity
        self.dismissCallback = onDismiss
    }

    public class Coordinator: PagerView<Content, DataType> { }
}
