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

public enum ListPosition {
    case beginning
    case end
}

public enum ZoomConfig {
    case disabled
    case custom(min: CGFloat, max: CGFloat, doubleTap: DoubleTap)
}

public struct Config<Element> {
    /// binding variable to control a custom background opacity. LazyPager is transparent by default
    public var backgroundOpacity: Binding<CGFloat>?
    
    /// Called when the view is done dismissing - dismiss gesture is disabled if nil
    public var dismissCallback: (() -> ())?
    
    /// Called when tapping once
    public var tapCallback: (() -> ())?
    
    /// Called when tapping twice
    public var doubleTapCallback: (() -> ())?
    
    /// Called when dragging begins
    public var dragCallback: (() -> ())?
    
    /// The offset used to trigger load loadMoreCallback
    public var loadMoreOn: LoadMore = .lastElement(minus: 3)
    
    /// Called when more content should be loaded
    public var loadMoreCallback: (() -> ())?
    
    /// Direction of the pager
    public var direction : Direction = .horizontal
    
    /// Called whent the end of data is reached and the user tries to swipe again
    public var overscrollCallback: ((ListPosition) -> ())?
    
    /// The element index + the offset while paging
    public var absoluteContentPosition: Binding<CGFloat>?
    
    /// Called every view update to get the zoom config
    public var zoomConfigGetter: (Element) -> ZoomConfig = { _ in .disabled }
    
    /// Called while zooming to provide the current zoom level for an element
    public var onZoomHandler: ((Element, CGFloat) -> ())?

    /// Advanced settings (only accessibleevia .settings)
    
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
    
    /// % ammount (from 0-1) of overscroll needed to call overscrollCallback
    public var overscrollThreshold: Double = 0.15
    
    /// The spacing between pages. Defaults to 0.
    public var pageSpacing: CGFloat = 0
}

public struct LazyPager<Element, DataCollecton: RandomAccessCollection, Content: View> where DataCollecton.Index == Int, DataCollecton.Element == Element {
    private var viewLoader: (Element) -> Content
    private var data: DataCollecton
    
    @State private var defaultPageInternal = 0
    private var providedPage: Binding<Int>?
    
    private var page: Binding<Int> {
        providedPage ?? Binding(
            get: { defaultPageInternal },
            set: { defaultPageInternal = $0 }
        )
    }
    
    var config = Config<Element>()
    
    public init(data: DataCollecton,
                page: Binding<Int>? = nil,
                direction: Direction = .horizontal,
                @ViewBuilder content: @escaping (Element) -> Content)  {
        self.data = data
        self.providedPage = page
        self.viewLoader = content
        self.config.direction = direction
    }
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
    
    func onDoubleTap(_ callback: @escaping () -> ()) -> LazyPager {
        var this = self
        this.config.doubleTapCallback = callback
        return this
    }
    
    func onDrag(_ callback: @escaping () -> ()) -> LazyPager {
        var this = self
        this.config.dragCallback = callback
        return this
    }
    
    func pageSpacing(_ spacing: CGFloat) -> LazyPager {
        var this = self
        this.config.pageSpacing = spacing
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
        this.config.zoomConfigGetter = { _ in
            return .custom(min: min, max: max, doubleTap: doubleTapGesture)
        }
        return this
    }
    
    func zoomable(onElement: @escaping (Element) -> ZoomConfig) -> LazyPager {
        var this = self
        this.config.zoomConfigGetter = onElement
        return this
    }
    
    func settings(_ adjust: @escaping (inout Config<Element>) -> ()) -> LazyPager {
        var this = self
        adjust(&this.config)
        return this
    }
    
    func overscroll(_ callback: @escaping (ListPosition) -> ()) -> LazyPager {
        var this = self
        this.config.overscrollCallback = callback
        return this
    }
    
    func absoluteContentPosition(_ absoluteContentPosition: Binding<CGFloat>? = nil) -> LazyPager {
        guard config.direction == .horizontal else {
            return self
        }
        var this = self
        this.config.absoluteContentPosition = absoluteContentPosition
        return this
    }
    
    func onZoom(_ onZoomHandler: @escaping (Element, CGFloat) -> ()) -> LazyPager {
        var this = self
        this.config.onZoomHandler = onZoomHandler
        return this
    }
}

extension LazyPager: UIViewControllerRepresentable {
    public func makeUIViewController(context: Context) -> ViewDataProvider<Content, DataCollecton, Element> {
        let provider = ViewDataProvider(data: data,
                                        page: page,
                                        config: config,
                                        viewLoader: viewLoader)
        DispatchQueue.main.async {
            provider.goToPage(page.wrappedValue, animated: false)
        }
        return provider
    }
    
    public func updateUIViewController(_ uiViewController: ViewDataProvider<Content, DataCollecton, Element>, context: Context) {
        uiViewController.viewLoader = viewLoader
        uiViewController.data = data
        defer { uiViewController.reloadViews() }
        if page.wrappedValue != uiViewController.pagerView.currentIndex {
            // Index was explicitly updated
            uiViewController.goToPage(page.wrappedValue, animated: context.transaction.animation != nil)
        }
        
        if page.wrappedValue >= data.count {
            uiViewController.goToPage(data.count - 1, animated: false)
        } else if page.wrappedValue < 0 {
            uiViewController.goToPage(0, animated: false)
        }
    }
}
