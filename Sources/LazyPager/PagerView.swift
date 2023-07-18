//
//  File.swift
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
    
    func loadView(at: Int) -> ZoomableView<Element, Content>?
    func updateHostedView(for zoomableView: ZoomableView<Element, Content>)
}

class PagerView<Element, Loader: ViewLoader, Content: View>: UIScrollView, UIScrollViewDelegate where Loader.Element == Element, Loader.Content == Content {
    var isFirstLoad = false
    var loadedViews = [ZoomableView<Element, Content>]()
    var config: Config
    weak var viewLoader: Loader?
    
    private var internalIndex: Int = 0
    var page: Binding<Int>
    
    var currentIndex: Int = 0 {
        didSet {
            computeViewState()
            page.wrappedValue = currentIndex
        }
    }
    
    init(page: Binding<Int>, config: Config) {
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
            goToPage(currentIndex)
            isFirstLoad = true
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
//        print(self.loadedViews.map { $0.index })
    }
    
    
    func addSubview(_ zoomView: ZoomableView<Element, Content>) {
        super.addSubview(zoomView)
        NSLayoutConstraint.activate([
            zoomView.widthAnchor.constraint(equalTo: frameLayoutGuide.widthAnchor),
            zoomView.heightAnchor.constraint(equalTo: frameLayoutGuide.heightAnchor),
        ])
    }
    
    func addFirstView(_ zoomView: ZoomableView<Element, Content>) {
        zoomView.leadingConstraint = zoomView.leadingAnchor.constraint(equalTo: leadingAnchor)
        zoomView.trailingConstraint = zoomView.trailingAnchor.constraint(equalTo: trailingAnchor)
        zoomView.leadingConstraint?.isActive = true
        zoomView.trailingConstraint?.isActive = true
    }
    
    func appendView(at index: Int) {
        guard let zoomView = viewLoader?.loadView(at: index) else {
            return
        }
        
        addSubview(zoomView)
        
        if let lastView = loadedViews.last {
            lastView.trailingConstraint?.isActive = false
            lastView.trailingConstraint = nil
            
            zoomView.leadingConstraint = zoomView.leadingAnchor.constraint(equalTo: lastView.trailingAnchor)
            zoomView.trailingConstraint = zoomView.trailingAnchor.constraint(equalTo: trailingAnchor)
            zoomView.leadingConstraint?.isActive = true
            zoomView.trailingConstraint?.isActive = true
            
        } else {
            addFirstView(zoomView)
        }
        loadedViews.append(zoomView)
        layoutSubviews()
    }
    
    func prependView(at index: Int) {
        guard let zoomView = viewLoader?.loadView(at: index) else {
            return
        }
        
        addSubview(zoomView)
        
        if let firstView = loadedViews.first {
            firstView.leadingConstraint?.isActive = false
            firstView.leadingConstraint = nil
            
            zoomView.leadingConstraint = zoomView.leadingAnchor.constraint(equalTo: leadingAnchor)
            zoomView.trailingConstraint = zoomView.trailingAnchor.constraint(equalTo: firstView.leadingAnchor)
            zoomView.leadingConstraint?.isActive = true
            zoomView.trailingConstraint?.isActive = true
            
        } else {
            addFirstView(zoomView)
        }
        
        layoutSubviews()
        
        loadedViews.insert(zoomView, at: 0)
        contentOffset.x += frame.size.width
        internalIndex += 1
        
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
            firstView.leadingConstraint?.isActive = false
            firstView.leadingConstraint = nil
            firstView.leadingConstraint = firstView.leadingAnchor.constraint(equalTo: leadingAnchor)
            firstView.leadingConstraint?.isActive = true
            
            if firstView.index > index {
                contentOffset.x -= frame.size.width
                internalIndex -= 1
            }
        }
        
        if let lastView = loadedViews.last {
            lastView.trailingConstraint?.isActive = false
            lastView.trailingConstraint = nil
            lastView.trailingConstraint = lastView.trailingAnchor.constraint(equalTo: trailingAnchor)
            lastView.trailingConstraint?.isActive = true
        }
    }
    
    
    func removeOutOfFrameViews() {
        for view in loadedViews {
            if abs(currentIndex - view.index) > config.preloadAmount {
                remove(view: view)
            }
        }
    }
    
    func resizeOutOfBoundsViews() {
        for v in loadedViews {
            if v.index != currentIndex, !isSubviewVisible(v, in: self) {
                v.zoomScale = 1
            }
        }
    }
    
    func isSubviewVisible(_ subview: UIView, in scrollView: UIScrollView) -> Bool {
        let visibleRect = CGRect(origin: scrollView.contentOffset, size: CGSize(width: scrollView.bounds.size.width - 1, height: scrollView.bounds.size.height))
        let subviewFrame = scrollView.convert(subview.frame, from: subview.superview)
        let intersectionRect = visibleRect.intersection(subviewFrame)
        return !intersectionRect.isNull && intersectionRect.size.height > 0 && intersectionRect.size.width > 0
    }
    
    func goToPage(_ page: Int) {
        guard let index = loadedViews.firstIndex(where: { $0.index == page }) else {
            return
        }
        contentOffset.x = CGFloat(index) * frame.size.width
        internalIndex = index
    }
    
    // MARK: UISCrollVieDelegate methods
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let visible = loadedViews.first(where: { isSubviewVisible($0, in: scrollView) }) else { return }
        guard let newIndex = loadedViews.firstIndex(where: { $0.index == visible.index }) else { return }
        if newIndex != internalIndex, !scrollView.isTracking {
            currentIndex = visible.index
            internalIndex = newIndex
        }
        resizeOutOfBoundsViews()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        resizeOutOfBoundsViews()
    }
}
