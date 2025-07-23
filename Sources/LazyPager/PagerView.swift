//
//  PagerView.swift
//  
//
//  Created by Brian Floersch on 7/8/23.
//

import Foundation
import UIKit
import SwiftUI

protocol ViewLoader: AnyObject {
    
    associatedtype Element
    associatedtype Content: View
    
    var dataCount: Int { get }
    
    func loadView(at: Int) -> ZoomableView<Element, Content>?
    func updateHostedView(for zoomableView: ZoomableView<Element, Content>)
}

class PagerView<Element, Loader: ViewLoader, Content: View>: UIScrollView, UIScrollViewDelegate where Loader.Element == Element, Loader.Content == Content {
    
    
    var pageSpacing: CGFloat {
        config.pageSpacing
    }
    var isFirstLoad = false
    var loadedViews = [ZoomableView<Element, Content>]()
    var config: Config<Element>
    weak var viewLoader: Loader?
    
    var isRotating = false
    var page: Binding<Int>
    
    var currentIndex: Int = 0 {
        didSet {
            loadMoreIfNeeded()
        }
    }
    
    var absoluteOffset: CGFloat {
        var absoluteOffset: CGFloat
        if config.direction == .horizontal {
            absoluteOffset = self.contentOffset.x / self.pageWidth
        } else {
            absoluteOffset = self.contentOffset.y / self.pageHeight
        }
        return absoluteOffset
    }
    
    var relativeIndex: Int {
        if absoluteOffset.isInfinite || absoluteOffset.isNaN {
            return 0
        }
        var idx = Int(round(absoluteOffset))
        idx = idx < 0 ? 0 : idx
        idx = idx >= loadedViews.count ? loadedViews.count-1 : idx
        return idx
    }
    
    var currentView: ZoomableView<Element, Content> {
        loadedViews[relativeIndex]
    }
    
    var pageWidth: CGFloat {
        if config.direction == .horizontal {
            return frame.width + pageSpacing
        }
        return frame.width
    }
    
    var pageHeight: CGFloat {
        if config.direction == .vertical {
            return frame.height + pageSpacing
        }
        return frame.height
    }
    
    init(page: Binding<Int>, config: Config<Element>) {
        self.currentIndex = page.wrappedValue
        self.page = page
        self.config = config
        super.init(frame: .zero)
        
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        backgroundColor = .clear
        decelerationRate = .fast
        delegate = self
        // DEBUG
//        backgroundColor = .blue
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if !isFirstLoad {
            ensureCurrentPage(animated: false)
            isFirstLoad = true
        } else if isRotating {
            ensureCurrentPage(animated: false)
        }
    }
    
    func computeViewState(immediate: Bool = false) {
        delegate = nil
        DispatchQueue.main.async {
            self.delegate = self
        }
        
        if subviews.isEmpty {
            for i in currentIndex...(currentIndex + config.preloadAmount) {
                if immediate {
                    appendView(at: i)
                } else {
                    scheduleAppend(at: i)
                }
            }
            for i in ((currentIndex - config.preloadAmount)..<currentIndex).reversed() {
                if immediate {
                    schedulePrepend(at: i)
                } else {
                    prependView(at: i)
                }
            }
        }
        
        if let lastView = loadedViews.last {
            let diff = lastView.index - currentIndex
            if diff < (config.preloadAmount) {
                for i in lastView.index..<(lastView.index + (config.preloadAmount - diff)) {
                    if immediate {
                        appendView(at: i + 1)
                    } else {
                        scheduleAppend(at: i + 1)
                    }
                }
            }
        }
        
        if let firstView = loadedViews.first {
            let diff = currentIndex - firstView.index
            if diff < (config.preloadAmount) {
                for i in (firstView.index - (config.preloadAmount - diff)..<firstView.index).reversed() {
                    if immediate {
                        schedulePrepend(at: i)
                    } else {
                        prependView(at: i)
                    }
                }
            }
        }
        self.removeOutOfFrameViews()
        if config.direction == .horizontal {
            contentInset = UIEdgeInsets(top: 0,
                                        left: -safeAreaInsets.left,
                                        bottom: 0,
                                        right: -safeAreaInsets.right)
        } else {
            contentInset = UIEdgeInsets(top: -safeAreaInsets.top,
                                        left: 0,
                                        bottom: -safeAreaInsets.bottom,
                                        right: 0)
        }
        
        // Debug
//         print(self.loadedViews.map { $0.index })
    }
    
    
    func addSubview(_ zoomView: ZoomableView<Element, Content>) {
        super.addSubview(zoomView)
        NSLayoutConstraint.activate([
            zoomView.widthAnchor.constraint(equalTo: frameLayoutGuide.widthAnchor),
            zoomView.heightAnchor.constraint(equalTo: frameLayoutGuide.heightAnchor),
        ])
    }
    
    func addFirstView(_ zoomView: ZoomableView<Element, Content>) {
        if config.direction == .horizontal {
            zoomView.leadingConstraint = zoomView.leadingAnchor.constraint(equalTo: leadingAnchor)
            zoomView.trailingConstraint = zoomView.trailingAnchor.constraint(equalTo: trailingAnchor)
            zoomView.leadingConstraint?.isActive = true
            zoomView.trailingConstraint?.isActive = true
        } else {
            zoomView.topConstraint = zoomView.topAnchor.constraint(equalTo: topAnchor)
            zoomView.bottomConstraint = zoomView.bottomAnchor.constraint(equalTo: bottomAnchor)
            zoomView.topConstraint?.isActive = true
            zoomView.bottomConstraint?.isActive = true
        }
    }
    
    func scheduleAppend(at index: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Ensure we are not trying to add a view that has already been loaded
            if self.loadedViews.contains(where: { $0.index == index }) {
                return
            }
            self.appendView(at: index)
        }
    }
    
    func appendView(at index: Int) {
        guard let zoomView = viewLoader?.loadView(at: index) else { return }
        
        addSubview(zoomView)
        
        if let lastView = loadedViews.last {
            if config.direction == .horizontal {
                lastView.trailingConstraint?.isActive = false
                lastView.trailingConstraint = nil
                
                zoomView.leadingConstraint = zoomView.leadingAnchor.constraint(equalTo: lastView.trailingAnchor, constant: pageSpacing)
                zoomView.trailingConstraint = zoomView.trailingAnchor.constraint(equalTo: trailingAnchor)
                zoomView.leadingConstraint?.isActive = true
                zoomView.trailingConstraint?.isActive = true
            } else {
                lastView.bottomConstraint?.isActive = false
                lastView.bottomConstraint = nil
                
                zoomView.topConstraint = zoomView.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: pageSpacing)
                zoomView.bottomConstraint = zoomView.bottomAnchor.constraint(equalTo: bottomAnchor)
                zoomView.topConstraint?.isActive = true
                zoomView.bottomConstraint?.isActive = true
            }
            
        } else {
            addFirstView(zoomView)
        }
        loadedViews.append(zoomView)
    }
    
    func schedulePrepend(at index: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Ensure we are not trying to add a view that has already been loaded
            if self.loadedViews.contains(where: { $0.index == index }) {
                return
            }
            self.prependView(at: index)
        }
    }
    
    func prependView(at index: Int) {
        guard let zoomView = viewLoader?.loadView(at: index) else { return }
        
        addSubview(zoomView)
        
        if let firstView = loadedViews.first {
            if config.direction == .horizontal {
                firstView.leadingConstraint?.isActive = false
                firstView.leadingConstraint = nil
                
                zoomView.leadingConstraint = zoomView.leadingAnchor.constraint(equalTo: leadingAnchor)
                zoomView.trailingConstraint = zoomView.trailingAnchor.constraint(equalTo: firstView.leadingAnchor, constant: -pageSpacing)
                zoomView.leadingConstraint?.isActive = true
                zoomView.trailingConstraint?.isActive = true
            } else {
                firstView.topConstraint?.isActive = false
                firstView.topConstraint = nil
                
                zoomView.topConstraint = zoomView.topAnchor.constraint(equalTo: topAnchor)
                zoomView.bottomConstraint = zoomView.bottomAnchor.constraint(equalTo: firstView.topAnchor, constant: -pageSpacing)
                zoomView.topConstraint?.isActive = true
                zoomView.bottomConstraint?.isActive = true
            }
            
        } else {
            addFirstView(zoomView)
        }
        
        loadedViews.insert(zoomView, at: 0)
        if config.direction == .horizontal {
            contentOffset.x += pageWidth
        } else {
            contentOffset.y += pageHeight
        }
    }
    
    func reloadViews() {
        for view in loadedViews {
            viewLoader?.updateHostedView(for: view)
        }
    }
    
    func remove(view: ZoomableView<Element, Content>) {
        guard let viewIndex = loadedViews.firstIndex(where: { $0.index == view.index }) else { return }
        
        let viewToDisconnect = loadedViews[viewIndex]
        let prevView: ZoomableView<Element, Content>? = loadedViews[safe: viewIndex - 1]
        let nextView: ZoomableView<Element, Content>? = loadedViews[safe: viewIndex + 1]
        
        let removedIndex = viewToDisconnect.index
        
        viewToDisconnect.removeFromSuperview()
        loadedViews.remove(at: viewIndex)
        
        if config.direction == .horizontal {
            if let prevView = prevView, let nextView = nextView {
                // Both exist, removing from the middle
                prevView.trailingConstraint?.isActive = false
                prevView.trailingConstraint = prevView.trailingAnchor.constraint(equalTo: nextView.leadingAnchor, constant: -pageSpacing)
                prevView.trailingConstraint?.isActive = true
            } else if let prevView = prevView {
                // This was the last view
                prevView.trailingConstraint?.isActive = false
                prevView.trailingConstraint = prevView.trailingAnchor.constraint(equalTo: trailingAnchor)
                prevView.trailingConstraint?.isActive = true
            } else if let nextView = nextView {
                // This was the first view
                nextView.leadingConstraint?.isActive = false
                nextView.leadingConstraint = nextView.leadingAnchor.constraint(equalTo: leadingAnchor)
                nextView.leadingConstraint?.isActive = true
            }
            
            if removedIndex < (loadedViews.first?.index ?? 0) {
                contentOffset.x -= pageWidth
            }
        } else {
            if let prevView = prevView, let nextView = nextView {
                // Both exist, removing from the middle
                prevView.bottomConstraint?.isActive = false
                prevView.bottomConstraint = prevView.bottomAnchor.constraint(equalTo: nextView.topAnchor, constant: -pageSpacing)
                prevView.bottomConstraint?.isActive = true
            } else if let prevView = prevView {
                // This was the last view
                prevView.bottomConstraint?.isActive = false
                prevView.bottomConstraint = prevView.bottomAnchor.constraint(equalTo: bottomAnchor)
                prevView.bottomConstraint?.isActive = true
            } else if let nextView = nextView {
                // This was the first view
                nextView.topConstraint?.isActive = false
                nextView.topConstraint = nextView.topAnchor.constraint(equalTo: topAnchor)
                nextView.topConstraint?.isActive = true
            }
            
            if removedIndex < (loadedViews.first?.index ?? 0) {
                contentOffset.y -= pageHeight
            }
        }
    }
    
    
    func removeOutOfFrameViews() {
        guard let viewLoader = viewLoader else { return }
        
        for view in loadedViews {
            if abs(currentIndex - view.index) > config.preloadAmount || view.index >= viewLoader.dataCount {
                remove(view: view)
            }
        }
    }
    
    func resizeOutOfBoundsViews() {
        for v in loadedViews {
            if v.index != currentIndex {
                v.zoomScale = 1
            }
        }
    }
    
    func goToPage(_ page: Int, animated: Bool) {
        currentIndex = page
        DispatchQueue.main.async {
            self.computeViewState(immediate: true)
            self.ensureCurrentPage(animated: animated)
        }
    }
    
    func ensureCurrentPage(animated: Bool) {
        guard let index = loadedViews.firstIndex(where: { $0.index == currentIndex }) else { return }
        if config.direction == .horizontal {
            setContentOffset(CGPoint(x: CGFloat(index) * pageWidth, y: contentOffset.y), animated: animated)
        } else {
            setContentOffset(CGPoint(x: contentOffset.x, y: CGFloat(index) * pageHeight), animated: animated)
        }
        self.currentView.dismissEnabled = true
    }
    
    func loadMoreIfNeeded() {
        guard let loadMoreCallback = config.loadMoreCallback else { return }
        guard case let .lastElement(offset) = config.loadMoreOn else { return }
        guard let viewLoader = viewLoader else { return }
        
        if currentIndex + offset >= viewLoader.dataCount - 1 {
            DispatchQueue.main.async {
                loadMoreCallback()
            }
        }
    }
    
    func scrollingFinished() {
        let newIndex = currentView.index
        
        if currentIndex != newIndex {
            currentIndex = newIndex
            page.wrappedValue = newIndex
        }
        
        computeViewState()
        
        hasNotfiedOverscroll = false
        resizeOutOfBoundsViews()
        if loadedViews.isEmpty { return }
        currentView.dismissEnabled = true
    }
    
    // MARK: UISCrollVieDelegate methods
    
    var lastPos: CGFloat = 0
    var hasNotfiedOverscroll = false
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        config.dragCallback?()
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let newIndex = currentView.index
        if currentIndex != newIndex {
            currentIndex = newIndex
            // To avoid modifying binding during view update
            DispatchQueue.main.async {
                self.page.wrappedValue = newIndex
            }
        }
        
        if let index = loadedViews[safe: relativeIndex]?.index {
            config.absoluteContentPosition?.wrappedValue = CGFloat(index) + absoluteOffset - CGFloat(relativeIndex)
        }
        
        if !hasNotfiedOverscroll {
            if relativeIndex >= loadedViews.count-1, absoluteOffset - CGFloat(relativeIndex) > config.overscrollThreshold {
                config.overscrollCallback?(.end)
                hasNotfiedOverscroll = true
            }
            
            if relativeIndex <= 0, absoluteOffset - CGFloat(relativeIndex) < -config.overscrollThreshold {
                config.overscrollCallback?(.beginning)
                hasNotfiedOverscroll = true
            }
        }
        
        if loadedViews.isEmpty { return }
        self.currentView.dismissEnabled = false
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let targetPage: CGFloat
        let velocityThreshold: CGFloat = 0.5 // a value to tune
        
        if config.direction == .horizontal {
            let currentRelativePage = scrollView.contentOffset.x / pageWidth
            if velocity.x > velocityThreshold {
                // Swiped forward
                targetPage = floor(currentRelativePage + 1)
            } else if velocity.x < -velocityThreshold {
                // Swiped backward
                targetPage = ceil(currentRelativePage - 1)
            } else {
                // No strong swipe, snap to nearest
                targetPage = round(currentRelativePage)
            }
            targetContentOffset.pointee.x = targetPage * pageWidth
        } else {
            let currentRelativePage = scrollView.contentOffset.y / pageHeight
            if velocity.y > velocityThreshold {
                targetPage = floor(currentRelativePage + 1)
            } else if velocity.y < -velocityThreshold {
                targetPage = ceil(currentRelativePage - 1)
            } else {
                targetPage = round(currentRelativePage)
            }
            targetContentOffset.pointee.y = targetPage * pageHeight
        }
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollingFinished()
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollingFinished()
    }
}
