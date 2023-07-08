//
//  File.swift
//  
//
//  Created by Brian Floersch on 7/8/23.
//

import Foundation
import SwiftUI
import UIKit

protocol ViewLoader: AnyObject {
    func loadView(at: Int) -> ZoomableView?
}

class UIPagerView: UIScrollView {
    var isFirstLoad = false
    var loadedViews = [ZoomableView]()
    let preloadAmount = 3
    weak var viewLoader: ViewLoader?
    weak var zoomViewDelegate: ZoomViewDelegate?
    
    private var internalIndex: Int = 0
    var page: Binding<Int>
    
    var currentIndex: Int = 0 {
        didSet {
            computeViewState()
            page.wrappedValue = currentIndex
        }
    }
    
    init(page: Binding<Int>) {
        self.currentIndex = page.wrappedValue
        self.page = page
        super.init(frame: .zero)
        
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
            for i in currentIndex...(currentIndex + preloadAmount) {
                appendView(at: i)
            }
            for i in ((currentIndex - preloadAmount)..<currentIndex).reversed() {
                prependView(at: i)
            }
        }
        
        if let lastView = loadedViews.last {
            let diff = lastView.index - currentIndex
            if diff < (preloadAmount) {
                for i in lastView.index..<(lastView.index + (preloadAmount - diff)) {
                    appendView(at: i + 1)
                }
            }
        }
        
        if let firstView = loadedViews.first {
            let diff = currentIndex - firstView.index
            if diff < (preloadAmount) {
                for i in (firstView.index - (preloadAmount - diff)..<firstView.index).reversed() {
                    prependView(at: i)
                }
            }
        }
        self.removeOutOfFrameViews()
        
        // Debug
//        print(self.loadedViews.map { $0.index })
    }
    
    
    func addSubview(_ zoomView: ZoomableView) {
        zoomView.zoomViewDelegate = zoomViewDelegate
        super.addSubview(zoomView)
        NSLayoutConstraint.activate([
            zoomView.widthAnchor.constraint(equalTo: frameLayoutGuide.widthAnchor),
            zoomView.heightAnchor.constraint(equalTo: frameLayoutGuide.heightAnchor),
        ])
    }
    
    func addFirstView(_ zoomView: ZoomableView) {
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
    
    func remove(view: ZoomableView) {
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
            if abs(currentIndex - view.index) > preloadAmount {
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
}

extension UIPagerView: UIScrollViewDelegate {
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let visible = loadedViews.first { isSubviewVisible($0, in: scrollView) }
        let newIndex = loadedViews.firstIndex(where: { $0.index == visible?.index })!
        if newIndex != internalIndex, !scrollView.isTracking {
            currentIndex = visible!.index
            internalIndex = newIndex
        }
        resizeOutOfBoundsViews()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        resizeOutOfBoundsViews()
    }
}

public class PagerView<Content: View, DataType> {
    private var viewLoader: (DataType) -> Content
    
    var data: [DataType]
    var backgroundOpacity: Binding<CGFloat>?
    var dismissCallback: (() -> ())?
    
    
    var scrollView: UIPagerView
    
    
    var contentTopToFrame: NSLayoutConstraint!
    var contentTopToContent: NSLayoutConstraint!
    var contentBottomToFrame: NSLayoutConstraint!
    
    
    init(data: [DataType],
         page: Binding<Int>,
         backgroundOpacity: Binding<CGFloat>?,
         dismissCallback: (() -> ())?,
         viewLoader: @escaping (DataType) -> Content) {
        
        self.data = data
        self.viewLoader = viewLoader
        self.scrollView = UIPagerView(page: page)
        self.scrollView.viewLoader = self
        self.scrollView.zoomViewDelegate = self
        self.backgroundOpacity = backgroundOpacity
        self.dismissCallback = dismissCallback
        
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .clear
        scrollView.isPagingEnabled = true
        
        scrollView.computeViewState()
    }
    
    func goToPage(_ page: Int) {
        scrollView.goToPage(page)
    }
}

extension PagerView: ZoomViewDelegate {
    func fadeProgress(val: CGFloat) {
        backgroundOpacity?.wrappedValue = val
    }
    func onDismiss() {
        // Cancel swiftUI dismiss animations
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            dismissCallback?()
        }
    }
}

extension PagerView: ViewLoader {
    func loadView(at index: Int) -> ZoomableView? {
        guard let dta = data[safe: index] else {
            return nil
        }
        
        let loadedContent = UIHostingController(rootView: viewLoader(dta)).view!
        
        loadedContent.translatesAutoresizingMaskIntoConstraints = false
        loadedContent.backgroundColor = .clear
        
        return ZoomableView(view: loadedContent, index: index)
    }
}
