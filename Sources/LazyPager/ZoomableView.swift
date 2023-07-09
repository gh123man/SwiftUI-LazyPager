//
//  ZoomableView.swift
//  ImageScrollView
//
//  Created by Brian Floersch on 7/4/23.
//

import Foundation
import UIKit
import SwiftUI

protocol ZoomViewDelegate: AnyObject {
    func fadeProgress(val: CGFloat)
    func onDismiss()
}

class ZoomableView: UIScrollView, UIScrollViewDelegate {
    
    var trailingConstraint: NSLayoutConstraint?
    var leadingConstraint: NSLayoutConstraint?
    
    var contentTopToContent: NSLayoutConstraint!
    var contentTopToFrame: NSLayoutConstraint!
    var contentBottomToFrame: NSLayoutConstraint!
    var contentBottomToView: NSLayoutConstraint!
    var bottomView: UIView
    weak var zoomViewDelegate: ZoomViewDelegate? {
        didSet {
            zoomViewDelegate?.fadeProgress(val: 1)
            self.updateState()
        }
    }
    
    var allowScroll: Bool = true {
        didSet {
            if allowScroll {
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
    
    var index: Int
    init(view: UIView, index: Int) {
        self.index = index
        let v = UIView()
        bottomView = v
        
        super.init(frame: .zero)
        
        translatesAutoresizingMaskIntoConstraints = false
        delegate = self
        maximumZoomScale = 10
        minimumZoomScale = 1
        bouncesZoom = true
        backgroundColor = .clear
        alwaysBounceVertical = true
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
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
        contentBottomToView = view.bottomAnchor.constraint(equalTo: v.topAnchor)
        
        v.translatesAutoresizingMaskIntoConstraints = false
        addSubview(v)
        
        
        NSLayoutConstraint.activate([
            v.bottomAnchor.constraint(equalTo: bottomAnchor),
            v.leadingAnchor.constraint(equalTo: frameLayoutGuide.leadingAnchor),
            v.trailingAnchor.constraint(equalTo: frameLayoutGuide.trailingAnchor),
            v.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        DispatchQueue.main.async {
            self.updateState()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        isZoomHappening = true
        updateState()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        isZoomHappening = false
        updateState()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateState()
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollView.subviews[0]
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let imageView = scrollView.subviews[0]
        
        let w: CGFloat = imageView.intrinsicContentSize.width * UIScreen.main.scale
        let h: CGFloat = imageView.intrinsicContentSize.height * UIScreen.main.scale


        let ratioW = imageView.frame.width / w
        let ratioH = imageView.frame.height / h

        let ratio = ratioW < ratioH ? ratioW : ratioH

        let newWidth = w*ratio
        let newHeight = h*ratio

        let left = 0.5 * (newWidth * scrollView.zoomScale > imageView.frame.width
                          ? (newWidth - imageView.frame.width)
                          : (scrollView.frame.width - imageView.frame.width))
        let top = 0.5 * (newHeight * scrollView.zoomScale > imageView.frame.height
                         ? (newHeight - imageView.frame.height)
                         : (scrollView.frame.height - imageView.frame.height))

        contentInset = UIEdgeInsets(top: top - safeAreaInsets.top, left: left, bottom: top - safeAreaInsets.bottom, right: left)
    }
    
    func updateState() {
        
        allowScroll = zoomScale == 1

        if contentOffset.y > 10 && zoomScale == 1 {
            allowScroll = true
            pinchGestureRecognizer?.isEnabled = false
        } else {
            pinchGestureRecognizer?.isEnabled = true
        }
        
        if allowScroll {
            // Counteract content inset adjustments. Makes .ignoresSafeArea() work
            contentInset = UIEdgeInsets(top: -safeAreaInsets.top, left: 0, bottom: -safeAreaInsets.bottom, right: 0)
            
            let offset = contentOffset.y
            
            if !isAnimating {
                if offset < 0 {
                    let nrom = normalize(from: 0, at: abs(offset), to: frame.size.height)
                    let nrom2 = normalize(from: 0, at: nrom, to: 0.2)
                    zoomViewDelegate?.fadeProgress(val: 1 - nrom2)
                } else {
                    zoomViewDelegate?.fadeProgress(val: 1)
                }
            }
            
            wasTracking = isTracking
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let offset = contentOffset.y
        let percentage = (offset / (contentSize.height - bounds.size.height)) * 100
        
        if wasTracking, percentage < -10, !isZoomHappening, velocity.y < -1.3 {
            isAnimating = true
            let ogFram = frame.origin
            DispatchQueue.main.async {
                withAnimation(.linear(duration: 0.2)) {
                    self.zoomViewDelegate?.fadeProgress(val: 0)
                }
                UIView.animate(withDuration: 0.2, animations: {
                    self.frame.origin = CGPoint(x: ogFram.x, y: self.frame.size.height)
                }) { _ in
                    self.zoomViewDelegate?.onDismiss()
                }
            }
        }
    }
}

