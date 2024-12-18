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
    
    var isFirstLoad = false
    var loadedViews = [ZoomableView<Element, Content>]()
    var config: Config<Element>
    weak var viewLoader: Loader?
    
    var isRotating = false
    var page: Binding<Int>
    
    var currentIndex: Int = 0 {
        didSet {
            computeViewState()
            loadMoreIfNeeded()
        }
    }
    
    init(page: Binding<Int>, config: Config<Element>) {
        self.currentIndex = page.wrappedValue
        self.page = page
        self.config = config
        super.init(frame: .zero)
        
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        backgroundColor = .clear
        isPagingEnabled = true
        delegate = self
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
    
    func computeViewState() {
        delegate = nil
        DispatchQueue.main.async {
            self.delegate = self
        }
        
        if subviews.isEmpty {
            for i in currentIndex...(currentIndex + config.preloadAmount) {
                appendView(at: i)
            }
            for i in ((currentIndex - config.preloadAmount)..<currentIndex).reversed() {
                prependView(at: i)
            }
        }
        
        if let lastView = loadedViews.last {
            let diff = lastView.index - currentIndex
            if diff < (config.preloadAmount) {
                for i in lastView.index..<(lastView.index + (config.preloadAmount - diff)) {
                    appendView(at: i + 1)
                }
            }
        }
        
        if let firstView = loadedViews.first {
            let diff = currentIndex - firstView.index
            if diff < (config.preloadAmount) {
                for i in (firstView.index - (config.preloadAmount - diff)..<firstView.index).reversed() {
                    prependView(at: i)
                }
            }
        }
        self.removeOutOfFrameViews()
        
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
    
    func appendView(at index: Int) {
        guard let zoomView = viewLoader?.loadView(at: index) else { return }
        
        addSubview(zoomView)
        
        if let lastView = loadedViews.last {
            if config.direction == .horizontal {
                lastView.trailingConstraint?.isActive = false
                lastView.trailingConstraint = nil
                
                zoomView.leadingConstraint = zoomView.leadingAnchor.constraint(equalTo: lastView.trailingAnchor)
                zoomView.trailingConstraint = zoomView.trailingAnchor.constraint(equalTo: trailingAnchor)
                zoomView.leadingConstraint?.isActive = true
                zoomView.trailingConstraint?.isActive = true
            } else {
                lastView.bottomConstraint?.isActive = false
                lastView.bottomConstraint = nil
                
                zoomView.topConstraint = zoomView.topAnchor.constraint(equalTo: lastView.bottomAnchor)
                zoomView.bottomConstraint = zoomView.bottomAnchor.constraint(equalTo: bottomAnchor)
                zoomView.topConstraint?.isActive = true
                zoomView.bottomConstraint?.isActive = true
            }
            
        } else {
            addFirstView(zoomView)
        }
        loadedViews.append(zoomView)
        layoutSubviews()
    }
    
    func prependView(at index: Int) {
        guard let zoomView = viewLoader?.loadView(at: index) else { return }
        
        addSubview(zoomView)
        
        if let firstView = loadedViews.first {
            if config.direction == .horizontal {
                firstView.leadingConstraint?.isActive = false
                firstView.leadingConstraint = nil
                
                zoomView.leadingConstraint = zoomView.leadingAnchor.constraint(equalTo: leadingAnchor)
                zoomView.trailingConstraint = zoomView.trailingAnchor.constraint(equalTo: firstView.leadingAnchor)
                zoomView.leadingConstraint?.isActive = true
                zoomView.trailingConstraint?.isActive = true
            } else {
                firstView.topConstraint?.isActive = false
                firstView.topConstraint = nil
                
                zoomView.topConstraint = zoomView.topAnchor.constraint(equalTo: topAnchor)
                zoomView.bottomConstraint = zoomView.bottomAnchor.constraint(equalTo: firstView.topAnchor)
                zoomView.topConstraint?.isActive = true
                zoomView.bottomConstraint?.isActive = true
            }
            
        } else {
            addFirstView(zoomView)
        }
        
        layoutSubviews()
        
        loadedViews.insert(zoomView, at: 0)
        if config.direction == .horizontal {
            contentOffset.x += frame.size.width
        } else {
            contentOffset.y += frame.size.height
        }
    }
    
    func reloadViews() {
        for view in loadedViews {
            viewLoader?.updateHostedView(for: view)
        }
    }
    
    func remove(view: ZoomableView<Element, Content>) {
        let index = view.index
        loadedViews.removeAll { $0.index == view.index }
        view.removeFromSuperview()
        
        if let firstView = loadedViews.first {
            
            if config.direction == .horizontal {
                firstView.leadingConstraint?.isActive = false
                firstView.leadingConstraint = nil
                firstView.leadingConstraint = firstView.leadingAnchor.constraint(equalTo: leadingAnchor)
                firstView.leadingConstraint?.isActive = true
                
                if firstView.index > index {
                    contentOffset.x -= frame.size.width
                }
            } else {
                firstView.topConstraint?.isActive = false
                firstView.topConstraint = nil
                firstView.topConstraint = firstView.topAnchor.constraint(equalTo: topAnchor)
                firstView.topConstraint?.isActive = true
                
                if firstView.index > index {
                    contentOffset.y -= frame.size.height
                }
            }
        }
        
        if let lastView = loadedViews.last {
            if config.direction == .horizontal {
                lastView.trailingConstraint?.isActive = false
                lastView.trailingConstraint = nil
                lastView.trailingConstraint = lastView.trailingAnchor.constraint(equalTo: trailingAnchor)
                lastView.trailingConstraint?.isActive = true
            } else {
                lastView.bottomConstraint?.isActive = false
                lastView.bottomConstraint = nil
                lastView.bottomConstraint = lastView.bottomAnchor.constraint(equalTo: bottomAnchor)
                lastView.bottomConstraint?.isActive = true
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
            self.ensureCurrentPage(animated: animated)
        }
    }
    
    func ensureCurrentPage(animated: Bool) {
        guard let index = loadedViews.firstIndex(where: { $0.index == currentIndex }) else { return }
        if config.direction == .horizontal {
            setContentOffset(CGPoint(x: CGFloat(index) * frame.size.width, y: contentOffset.y), animated: animated)
        } else {
            setContentOffset(CGPoint(x: contentOffset.x, y: CGFloat(index) * frame.size.height), animated: animated)
        }
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
    
    // MARK: UISCrollVieDelegate methods
    
    var lastPos: CGFloat = 0
    var hasNotfiedOverscroll = false
    var scrollSettled = true

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var relativeIndex: Int
        var absoluteOffset: CGFloat
        if config.direction == .horizontal {
            absoluteOffset = scrollView.contentOffset.x / scrollView.frame.width
            relativeIndex = Int(round(absoluteOffset))
        } else {
            absoluteOffset = scrollView.contentOffset.y / scrollView.frame.height
            relativeIndex = Int(round(absoluteOffset))
        }
        relativeIndex = relativeIndex < 0 ? 0 : relativeIndex
        relativeIndex = relativeIndex >= loadedViews.count ? loadedViews.count-1 : relativeIndex
        
        if !scrollView.isTracking, !isRotating  {
            currentIndex = loadedViews[relativeIndex].index
            page.wrappedValue = currentIndex
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
        
        // Horribly janky way to detect when scrolling (both touching and animation) is finnished.
        let caputred: CGFloat
        
        if config.direction == .horizontal {
            caputred = scrollView.contentOffset.x
        } else {
            caputred = scrollView.contentOffset.y
        }
        
        lastPos = caputred
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            if self.lastPos == caputred, !scrollView.isTracking {
                self.hasNotfiedOverscroll = false
                self.resizeOutOfBoundsViews()
                self.scrollSettled = true
            }
        }
    }
}
