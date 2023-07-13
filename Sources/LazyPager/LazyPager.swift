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
    /// binding variable to control a custom background opacity. LazyPager is transparent by default
    public var backgroundOpacity: Binding<CGFloat>?
    
    /// The minimum zoom level (https://developer.apple.com/documentation/uikit/uiscrollview/1619428-minimumzoomscale)
    public var minZoom: CGFloat = 1
    
    /// The maximum zoom level (https://developer.apple.com/documentation/uikit/uiscrollview/1619408-maximumzoomscale)
    public var maxZoom: CGFloat = 1
    
    /// How to handle double tap events
    public var doubleTapSetting: DoubleTap = .disabled
    
    /// Called when the view is done dismissing - dismiss gesture is disabled if nil
    public var dismissCallback: (() -> ())?
    
    /// Called when tapping once
    public var tapCallback: (() -> ())?
    
    /// Advanced settings (only accessible via .settings)
    
    /// How may out of view pages to load in advance (forward and backwards)
    public var preloadAmount: Int = 3
    
    /// Minimum swipe velocity needed to trigger a dismiss
    public var dismissVelocity: CGFloat = 1.3
    
    /// the minimum % (between 0 and 1) you need to drag to trigger a dismiss
    public var dismissTriggerOffset: CGFloat = 0.1
    
    /// How long to animate the dismiss once done dragging
    public var dismissAnimationLength: CGFloat = 0.2
    
    /// Cancel SwiftUI animations. Default to true because the dismiss gesture is already animated.
    /// Stacking animations can cause undesirable behavior
    public var shouldCancelSwiftUIAnimationsOnDismiss = true
    
    /// At what drag % (between 0 and 1) the background should be fully transparent
    public var fullFadeOnDragAt: CGFloat = 0.2
    
    /// The minimum scroll distance the in which the pinch gesture is enabled
    public var pinchGestureEnableOffset: Double = 10
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
        return context.coordinator.pagerView
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(data: data,
                           page: page,
                           config: config,
                           viewLoader: viewLoader)
    }

    public func updateUIView(_ uiView: UIScrollView, context: Context) {}
}
