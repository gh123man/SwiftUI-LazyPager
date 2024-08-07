//
//  LazyPager.swift
//  LazyPager
//
//  Created by Brian Floersch on 7/6/23.
//

import Foundation
import UIKit
import SwiftUI

public enum LoadMore {
    case lastElement(minus: Int = 0)
}

public enum DoubleTap {
    case disabled
    case scale(CGFloat)
}

public enum Direction {
    case horizontal
    case vertical
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
    
    /// The offset used to trigger load loadMoreCallback
    public var loadMoreOn: LoadMore = .lastElement(minus: 3)
    
    /// Called when more content should be loaded
    public var loadMoreCallback: (() -> ())?
    
    /// Direction of the pager
    public var direction : Direction = .horizontal
    
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

public struct LazyPager<Element, DataCollecton: RandomAccessCollection, Content: View> where DataCollecton.Index == Int, DataCollecton.Element == Element {
    private var viewLoader: (Element) -> Content
    private var data: DataCollecton
    private var page: Binding<Int>
    
    var config = Config()
    
    public init(data: DataCollecton,
                page: Binding<Int> = .constant(0),
                direction: Direction = .horizontal,
                @ViewBuilder content: @escaping (Element) -> Content)  {
        self.data = data
        self.page = page
        self.viewLoader = content
        self.config.direction = direction
    }

    public class Coordinator: ViewDataProvider<Content, DataCollecton, Element> { }
}

public extension LazyPager {
    func onDismiss(backgroundOpacity: Binding<CGFloat>? = nil, _ callback: @escaping () -> ()) -> LazyPager {
        guard config.direction == .horizontal else {
            return self
        }
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
    
    func shouldLoadMore(on: LoadMore = .lastElement(minus: 3), _ callback: @escaping () -> ()) -> LazyPager {
        var this = self
        this.config.loadMoreOn = on
        this.config.loadMoreCallback = callback
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

extension LazyPager: UIViewControllerRepresentable {
    
    public func makeUIViewController(context: Context) -> Coordinator {
        DispatchQueue.main.async {
            context.coordinator.goToPage(page.wrappedValue)
        }
        return context.coordinator
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(data: data,
                           page: page,
                           config: config,
                           viewLoader: viewLoader)
    }

    public func updateUIViewController(_ uiViewController: Coordinator, context: Context) {
        
        uiViewController.viewLoader = viewLoader
        uiViewController.data = data
        defer { uiViewController.reloadViews() }
        if page.wrappedValue != uiViewController.pagerView.currentIndex {
            // Index was explicitly updated
            uiViewController.goToPage(page.wrappedValue)
        }
        
        if page.wrappedValue >= data.count {
            uiViewController.goToPage(data.count - 1)
        } else if page.wrappedValue < 0 {
            uiViewController.goToPage(0)
        }
        
    }
}
