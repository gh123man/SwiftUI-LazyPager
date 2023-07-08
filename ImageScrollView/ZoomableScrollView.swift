//
//  ZoomableScrollView.swift
//  ImageScrollView
//
//  Created by Brian Floersch on 7/6/23.
//

import Foundation
import UIKit
import SwiftUI

extension ZoomableScrollView {
    func onDismiss(backgroundOpacity: Binding<CGFloat>? = nil, _ callback: @escaping () -> ()) -> ZoomableScrollView {
        return ZoomableScrollView(data: self.data,
                                  page: self.page,
                                  backgroundOpacity: backgroundOpacity,
                                  onDismiss: callback,
                                  content: self.viewLoader)
    }
}


struct ZoomableScrollView<Content: View, DataType>: UIViewRepresentable {
    private var viewLoader: (DataType) -> Content
    private var data: [DataType]
    private var page: Binding<Int>
    
    var backgroundOpacity: Binding<CGFloat>?
    var dismissCallback: (() -> ())?
    
    init(data: [DataType],
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

    func makeUIView(context: Context) -> UIScrollView {
        DispatchQueue.main.async {
            context.coordinator.goToPage(page.wrappedValue)
        }
        return context.coordinator.scrollView
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(data: data,
                           page: page,
                           backgroundOpacity: backgroundOpacity,
                           dismissCallback: dismissCallback,
                           viewLoader: viewLoader)
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
//        context.coordinator.goToPage(index)
    }

    // MARK: - Coordinator

    class Coordinator: UIScrollView, UIScrollViewDelegate, ZoomViewDelegate {
        private var viewLoader: (DataType) -> Content
        
        var data: [DataType]
        var backgroundOpacity: Binding<CGFloat>?
        var dismissCallback: (() -> ())?
        
        let preloadAmount = 3
        
        var scrollView: UIScrollView {
            return self
        }
        var loadedViews = [ZoomableView]()
        
        var contentTopToFrame: NSLayoutConstraint!
        var contentTopToContent: NSLayoutConstraint!
        var contentBottomToFrame: NSLayoutConstraint!
        
        var isFirstLoad = false

        private var internalIndex: Int = 0
        var page: Binding<Int>
        var currentIndex: Int = 0 {
            didSet {
                computeViewState()
                page.wrappedValue = currentIndex
            }
        }
        
        init(data: [DataType],
             page: Binding<Int>,
             backgroundOpacity: Binding<CGFloat>?,
             dismissCallback: (() -> ())?,
             viewLoader: @escaping (DataType) -> Content) {
            
            self.data = data
            self.viewLoader = viewLoader
            self.currentIndex = page.wrappedValue
            self.page = page
            self.backgroundOpacity = backgroundOpacity
            self.dismissCallback = dismissCallback
            super.init(frame: .zero)
            
            scrollView.showsVerticalScrollIndicator = false
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.backgroundColor = .clear
            scrollView.isPagingEnabled = true
            
            scrollView.delegate = self
            computeViewState()
            
//            DispatchQueue.main.async {
//                self.superview?.superview?.backgroundColor = .clear
//            }
            
        }
        
        required init?(coder: NSCoder) {
            fatalError("Not implemented")
        }
        
        func computeViewState() {
            scrollView.delegate = nil
            DispatchQueue.main.async {
                self.scrollView.delegate = self
            }
            
            if scrollView.subviews.isEmpty {
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
            print(self.loadedViews.map { $0.index })
        }
        
        
        func removeOutOfFrameViews() {
            for view in loadedViews {
                if abs(currentIndex - view.index) > preloadAmount {
                    remove(view: view)
                }
            }
        }
        
        func remove(view: ZoomableView) {
            let index = view.index
            loadedViews.removeAll { $0.index == view.index }
            view.removeFromSuperview()
            
            if let firstView = loadedViews.first {
                firstView.leadingConstraint?.isActive = false
                firstView.leadingConstraint = nil
                firstView.leadingConstraint = firstView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor)
                firstView.leadingConstraint?.isActive = true
                
                if firstView.index > index {
                    scrollView.contentOffset.x -= scrollView.frame.size.width
                    internalIndex -= 1
                }
            }
            
            if let lastView = loadedViews.last {
                lastView.trailingConstraint?.isActive = false
                lastView.trailingConstraint = nil
                lastView.trailingConstraint = lastView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)
                lastView.trailingConstraint?.isActive = true
            }
        }
        
        func loadView(at index: Int) -> ZoomableView? {
            guard let dta = data[safe: index] else {
                return nil
            }
            
            let loadedContent = UIHostingController(rootView: viewLoader(dta)).view!
            
            loadedContent.translatesAutoresizingMaskIntoConstraints = false
            loadedContent.backgroundColor = .clear
            
            return ZoomableView(view: loadedContent, index: index)
        }
        
        func addSubview(_ zoomView: ZoomableView) {
            zoomView.zoomViewDelegate = self
            scrollView.addSubview(zoomView)
            NSLayoutConstraint.activate([
                zoomView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
                zoomView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
            ])
        }
        
        func addFirstView(_ zoomView: ZoomableView) {
            zoomView.leadingConstraint = zoomView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor)
            zoomView.trailingConstraint = zoomView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)
            zoomView.leadingConstraint?.isActive = true
            zoomView.trailingConstraint?.isActive = true
        }
        
        func appendView(at index: Int) {
            guard let zoomView = loadView(at: index) else {
                return
            }
            
            addSubview(zoomView)
            
            if let lastView = loadedViews.last {
                lastView.trailingConstraint?.isActive = false
                lastView.trailingConstraint = nil
                
                zoomView.leadingConstraint = zoomView.leadingAnchor.constraint(equalTo: lastView.trailingAnchor)
                zoomView.trailingConstraint = zoomView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)
                zoomView.leadingConstraint?.isActive = true
                zoomView.trailingConstraint?.isActive = true
                
            } else {
                addFirstView(zoomView)
            }
            loadedViews.append(zoomView)
            layoutSubviews()
        }
        
        func prependView(at index: Int) {
            guard let zoomView = loadView(at: index) else {
                return
            }
            
            addSubview(zoomView)
            
            if let firstView = loadedViews.first {
                firstView.leadingConstraint?.isActive = false
                firstView.leadingConstraint = nil
                
                zoomView.leadingConstraint = zoomView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor)
                zoomView.trailingConstraint = zoomView.trailingAnchor.constraint(equalTo: firstView.leadingAnchor)
                zoomView.leadingConstraint?.isActive = true
                zoomView.trailingConstraint?.isActive = true
                
            } else {
                addFirstView(zoomView)
            }
            
            layoutSubviews()
            
            loadedViews.insert(zoomView, at: 0)
            scrollView.contentOffset.x += scrollView.frame.size.width
            internalIndex += 1
            
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let visible = loadedViews.first { isSubviewVisible($0, in: scrollView) }
            let newIndex = loadedViews.firstIndex(where: { $0.index == visible?.index })!
            if newIndex != internalIndex, !isTracking {
                currentIndex = visible!.index
                internalIndex = newIndex
            }
            resizeOutOfBoundsViews()
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
            scrollView.contentOffset.x = CGFloat(index) * scrollView.frame.size.width
            internalIndex = index
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            if !isFirstLoad {
                goToPage(currentIndex)
                isFirstLoad = true
            }
        }
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
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            resizeOutOfBoundsViews()
        }
    }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct ClearFullScreenBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
