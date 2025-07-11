//
//  ZoomableView.swift
//  LazyPager
//
//  Created by Brian Floersch on 7/4/23.
//

import Foundation
import UIKit
import SwiftUI

class ZoomableView<Element, Content: View>: UIScrollView, UIScrollViewDelegate {
    
    var trailingConstraint: NSLayoutConstraint?
    var leadingConstraint: NSLayoutConstraint?
    var topConstraint: NSLayoutConstraint?
    var bottomConstraint: NSLayoutConstraint?
    var contentTopToContent: NSLayoutConstraint!
    var contentTopToFrame: NSLayoutConstraint!
    var contentBottomToFrame: NSLayoutConstraint!
    var contentBottomToView: NSLayoutConstraint!
    
    var config: Config<Element>
    var bottomView: UIView
    
    var allowScroll: Bool = true {
        didSet {
            if allowScroll, config.direction == .horizontal {
                contentTopToFrame.isActive = false
                contentBottomToFrame.isActive = false
                bottomView.isHidden = false
                
                contentTopToContent.isActive = true
                contentBottomToView.isActive = true
            } else {
                contentTopToContent.isActive = false
                contentBottomToView.isActive = false
                
                contentTopToFrame.isActive = true
                contentBottomToFrame.isActive = true
                bottomView.isHidden = true
            }
        }
    }
    
    var wasTracking = false
    var isAnimating = false
    var isZoomHappening = false
    var lastInset: CGFloat = 0
    var isAnimatingZoom = false
    var currentZoomInsetAnimation: UIViewPropertyAnimator?
    
    var hostingController: UIHostingController<Content>
    var index: Int
    var data: Element
    var doubleTap: DoubleTap?
    var lastBoundsSize: CGSize?
    
    var view: UIView {
        return hostingController.view
    }
    
    init(hostingController: UIHostingController<Content>, index: Int, data: Element, config: Config<Element>) {
        self.index = index
        self.hostingController = hostingController
        self.data = data
        self.config = config
        
        let v = UIView()
        self.bottomView = v
        
        super.init(frame: .zero)
        
        translatesAutoresizingMaskIntoConstraints = false
        delegate = self
        
        updateZoomConfig()
        
        bouncesZoom = true
        backgroundColor = .clear
        alwaysBounceVertical = false
        contentInsetAdjustmentBehavior = .always
        if config.dismissCallback != nil {
            alwaysBounceVertical = true
        }
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        // DEBUG
//        backgroundColor = .red
        addSubview(view)
        
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.widthAnchor.constraint(equalTo: frameLayoutGuide.widthAnchor),
            view.heightAnchor.constraint(equalTo: frameLayoutGuide.heightAnchor),
        ])
        
        contentTopToFrame = view.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor)
        contentTopToContent = view.topAnchor.constraint(equalTo: topAnchor)
        contentBottomToFrame = view.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor)
        contentBottomToView = view.bottomAnchor.constraint(equalTo: bottomView.topAnchor)
        
        v.translatesAutoresizingMaskIntoConstraints = false
        addSubview(v)

//        This is for future support of a drawer view
        let constant: CGFloat = config.dismissCallback == nil ? 0 : 1

        NSLayoutConstraint.activate([
          v.bottomAnchor.constraint(equalTo: bottomAnchor),
          v.leadingAnchor.constraint(equalTo: frameLayoutGuide.leadingAnchor),
          v.trailingAnchor.constraint(equalTo: frameLayoutGuide.trailingAnchor),
          v.heightAnchor.constraint(equalToConstant: constant)
        ])
        
        var singleTapGesture: UITapGestureRecognizer?
        if config.tapCallback != nil {
            let gesture = UITapGestureRecognizer(target: self, action: #selector(singleTap(_:)))
            gesture.numberOfTapsRequired = 1
            gesture.numberOfTouchesRequired = 1
            addGestureRecognizer(gesture)
            singleTapGesture = gesture
        }
                
        func setupDoubleTapGesture() {
            let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap(_:)))
            doubleTapRecognizer.numberOfTapsRequired = 2
            doubleTapRecognizer.numberOfTouchesRequired = 1
            addGestureRecognizer(doubleTapRecognizer)            
            singleTapGesture?.require(toFail: doubleTapRecognizer)
        }
        
        if case .scale = doubleTap {
            setupDoubleTapGesture()
        } else if config.doubleTapCallback != nil {
            setupDoubleTapGesture()
        }
        
        DispatchQueue.main.async {
            self.updateState()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    func updateZoomConfig() {
        switch config.zoomConfigGetter(data) {
        case .disabled:
            maximumZoomScale = 1
            minimumZoomScale = 1
            doubleTap = nil
        case let .custom(min, max, doubleTap):
            minimumZoomScale = min
            maximumZoomScale = max
            self.doubleTap = doubleTap
        }
    }
    
    @objc func singleTap(_ recognizer: UITapGestureRecognizer) {
        config.tapCallback?()
    }
    
    @objc func onDoubleTap(_ recognizer: UITapGestureRecognizer) {
        config.doubleTapCallback?()
        
        if case let .scale(scale) = doubleTap {
            let pointInView = recognizer.location(in: view)
            zoom(at: pointInView, scale: scale)
        }
    }
    
    func updateState() {
        updateZoomConfig()
        allowScroll = zoomScale == 1

        if contentOffset.y > config.pinchGestureEnableOffset, allowScroll {
            pinchGestureRecognizer?.isEnabled = false
        } else {
            pinchGestureRecognizer?.isEnabled = true
        }
        
        if allowScroll {
            if !isAnimating, config.dismissCallback != nil {
                let offset = contentOffset.y
                if offset < safeAreaInsets.top + safeAreaInsets.bottom {
                    let absoluteDragOffset = normalize(from: 0, at: abs(offset), to: frame.size.height)
                    let fadeOffset = normalize(from: 0, at: absoluteDragOffset, to: config.fullFadeOnDragAt)
                    config.backgroundOpacity?.wrappedValue = 1 - fadeOffset
                } else {
                    DispatchQueue.main.async {
                        self.config.backgroundOpacity?.wrappedValue = 1
                    }
                }
            }
            wasTracking = isTracking
        }
    }
    
    func zoom(at point: CGPoint, scale: CGFloat) {
        let mid = lerp(from: minimumZoomScale, to: maximumZoomScale, by: scale)
        let newZoomScale = zoomScale == minimumZoomScale ? mid : minimumZoomScale
        let size = bounds.size
        let w = size.width / newZoomScale
        let h = size.height / newZoomScale
        let x = point.x - (w * 0.5)
        let y = point.y - (h * 0.5)
        zoom(to: CGRect(x: x, y: y, width: w, height: h), animated: true)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Ensures insets are updated when the screen rotates
        if bounds.size != lastBoundsSize {
            lastBoundsSize = bounds.size
            updateInsets()
        }
    }
    
    // MARK: UIScrollViewDelegate methods
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        isZoomHappening = true
        updateState()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        isZoomHappening = false
        updateState()
        updateInsets()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateState()
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return view
    }
    
    func updateInsets() {
        let w: CGFloat = view.intrinsicContentSize.width * UIScreen.main.scale
        let h: CGFloat = view.intrinsicContentSize.height * UIScreen.main.scale
        
        let ratioW = view.frame.width / w
        let ratioH = view.frame.height / h
        
        let ratio = ratioW < ratioH ? ratioW : ratioH
        
        let newWidth = w*ratio
        let newHeight = h*ratio
        
        let left = 0.5 * (newWidth * zoomScale > view.frame.width
                          ? (newWidth - view.frame.width)
                          : (frame.width - view.frame.width))
        let top = 0.5 * (newHeight * zoomScale > view.frame.height
                         ? (newHeight - view.frame.height)
                         : (frame.height - view.frame.height))
        
        if zoomScale <= maximumZoomScale {
            let targetInsets = UIEdgeInsets(
                top: top - self.safeAreaInsets.top,
                left: left - self.safeAreaInsets.left,
                bottom: top - self.safeAreaInsets.bottom,
                right: left - self.safeAreaInsets.right
            )
            
            UIView.animate(withDuration: 0.3) {
                self.contentInset = targetInsets
            }
        }
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {

        let scrollViewSize = scrollView.bounds.size
        let zoomViewSize = view.frame.size

        let horizontalInset = max(0, (scrollViewSize.width - zoomViewSize.width) / 2)
        let verticalInset = max(0, (scrollViewSize.height - zoomViewSize.height) / 2)

        scrollView.contentInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
        config.onZoomHandler?(data, scrollView.zoomScale)
    }
    
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let percentage = contentOffset.y / (contentSize.height - bounds.size.height)
        
        if wasTracking,
           percentage < -config.dismissTriggerOffset,
           !isZoomHappening,
           velocity.y < -config.dismissVelocity,
           config.dismissCallback != nil {
            
            isAnimating = true
            let ogFram = frame.origin
            
            withAnimation(.linear(duration: self.config.dismissAnimationLength)) {
                self.config.backgroundOpacity?.wrappedValue = 0
            }
            
            frame.origin.y = -contentOffset.y
            
            UIView.animate(withDuration: self.config.dismissAnimationLength, animations: {
                self.frame.origin = CGPoint(x: ogFram.x, y: self.frame.size.height)
            }) { _ in
                if self.config.shouldCancelSwiftUIAnimationsOnDismiss {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        self.config.dismissCallback?()
                    }
                } else {
                    self.config.dismissCallback?()
                }
            }
        }
    }
}
