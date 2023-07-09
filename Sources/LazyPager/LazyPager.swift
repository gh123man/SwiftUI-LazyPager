//
//  ZoomableScrollView.swift
//  ImageScrollView
//
//  Created by Brian Floersch on 7/6/23.
//

import Foundation
import UIKit
import SwiftUI

public enum DoubleTap {
    case disabled
    case scale(CGFloat)
}

public struct Config {
    public var backgroundOpacity: Binding<CGFloat>?
    public var minZoom: CGFloat = 1
    public var maxZoom: CGFloat = 1
    public var doubleTapSetting: DoubleTap = .disabled
    public var dismissCallback: (() -> ())?
    public var tapCallback: (() -> ())?
    
    public var preloadAmount: Int = 3
    public var dismissVelocity: CGFloat = 1.3
    public var dismissAnimationLength: CGFloat = 0.2
    public var dismissTriggerOffset: CGFloat = 0.1
    public var shouldCacnelSwiftUIAnimationsOnDismiss = true
    public var fullFadeOnDragAt: CGFloat = 0.2
}

public struct LazyPager<Content: View, DataType> {
    private var viewLoader: (DataType) -> Content
    private var data: [DataType]
    private var page: Binding<Int>
    
    var config = Config()
    
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
        this.config.backgroundOpacity = backgroundOpacity
        this.config.dismissCallback = callback
        return this
    }
    
    func onTap(_ callback: @escaping () -> ()) -> LazyPager {
        var this = self
        this.config.tapCallback = callback
        return this
    }
    
    func zoomable(min: CGFloat, max: CGFloat, doubleTapGesture: DoubleTap = .scale(0.5)) -> LazyPager {
        var this = self
        this.config.minZoom = min
        this.config.maxZoom = max
        this.config.doubleTapSetting = doubleTapGesture
        return this
    }
    
    func settings(_ adjust: @escaping (inout Config) -> ()) -> LazyPager {
        var this = self
        adjust(&this.config)
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
                           config: config,
                           viewLoader: viewLoader)
    }

    public func updateUIView(_ uiView: UIScrollView, context: Context) {}
}
