//
//  ZoomableView.swift
//  LazyPager
//
//  Created by Brian Floersch on 7/4/23.
//

import Foundation
import UIKit
import SwiftUI

class ZoomableView<Element, Content: View>: UIScrollView, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
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
    var isZoomHappening = false
    var dismissEnabled = false // Contorlled by PagerView to prevent flicker
    var lastInset: CGFloat = 0
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
        panGestureRecognizer.delegate = self
        
        updateZoomConfig()
        
        bouncesZoom = true
        backgroundColor = .clear
        alwaysBounceVertical = false
        contentInsetAdjustmentBehavior = .never
        if config.dismissCallback != nil {
            alwaysBounceVertical = true
        }
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        decelerationRate = .fast
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
            updateInsets()
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
            if dismissEnabled, config.dismissCallback != nil {
                let offset = contentOffset.y
                if offset < 0 {
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
                top: top,
                left: left,
                bottom: top,
                right: left
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
            
            dismissEnabled = false // prevent touch interaction from messing with animation of opacity.
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
    
    // MARK: UIGestureRecognizerDelegate
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // We only want to intercept our own pan gesture.
        guard gestureRecognizer == self.panGestureRecognizer else {
            return true
        }

        let panGesture = self.panGestureRecognizer
        let velocity = panGesture.velocity(in: self)

        // This logic is for the horizontal pager.
        if config.direction == .horizontal {
            // If the swipe is mostly vertical, it's for dismissal. Let it happen.
            if abs(velocity.y) > abs(velocity.x) {
                return true
            }

            // It's a horizontal swipe. Should we let our own pan gesture begin?

            // If not zoomed, NO. The pager should handle all horizontal movement.
            if zoomScale <= minimumZoomScale {
                return false // Prevent our pan, let PagerView handle it.
            }

            // If we ARE zoomed, check if we're at the horizontal edges.
            let maxOffsetX = contentSize.width - bounds.width + contentInset.right
            let minOffsetX = -contentInset.left
            
            let isAtRightEdge = contentOffset.x >= maxOffsetX - 1.0
            let isAtLeftEdge = contentOffset.x <= minOffsetX + 1.0

            // At the right edge and trying to swipe left (to the next page).
            if isAtRightEdge && velocity.x < 0 {
                return false // Prevent our pan, let PagerView handle it.
            }

            // At the left edge and trying to swipe right (to the previous page).
            if isAtLeftEdge && velocity.x > 0 {
                return false // Prevent our pan, let PagerView handle it.
            }
        } else { // Vertical Pager
            // If the swipe is mostly horizontal, let it happen.
            if abs(velocity.x) > abs(velocity.y) {
                return true
            }

            // It's a vertical swipe. Should we let our own pan gesture begin?

            // If not zoomed, NO. The pager should handle all vertical movement.
            if zoomScale <= minimumZoomScale {
                return false // Prevent our pan, let PagerView handle it.
            }

            // If we ARE zoomed, check if we're at the vertical edges.
            let maxOffsetY = contentSize.height - bounds.height + contentInset.bottom
            let minOffsetY = -contentInset.top

            let isAtBottomEdge = contentOffset.y >= maxOffsetY - 1.0
            let isAtTopEdge = contentOffset.y <= minOffsetY + 1.0

            // At the bottom edge and trying to swipe up (to the next page).
            if isAtBottomEdge && velocity.y < 0 {
                return false // Prevent our pan, let PagerView handle it.
            }

            // At the top edge and trying to swipe down (to the previous page).
            if isAtTopEdge && velocity.y > 0 {
                return false // Prevent our pan, let PagerView handle it.
            }
        }
        
        // If we're not at an edge while zoomed, our pan gesture should begin.
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // We no longer need simultaneous recognition. This simplifies the logic and
        // prevents the differential panning issues.
        return false
    }
}
