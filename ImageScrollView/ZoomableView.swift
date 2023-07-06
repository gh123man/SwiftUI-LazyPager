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

func lerp(from: CGFloat, to: CGFloat, by: CGFloat) -> CGFloat {
    return from * (1 - by) + to * by
}

func normalize(from min: CGFloat, to max: CGFloat, by val: CGFloat) -> CGFloat {
    let v = (val - min) / (max - min)
    return v < 0 ? 0 : v > 1 ? 1 : v
}

class ZoomableView: UIScrollView, UIScrollViewDelegate {
    
    var trailingConstraint: NSLayoutConstraint?
    var leadingConstraint: NSLayoutConstraint?
    
    var contentTopToContent: NSLayoutConstraint!
    var contentTopToFrame: NSLayoutConstraint!
    var contentBottomToFrame: NSLayoutConstraint!
    var contentBottomToView: NSLayoutConstraint!
    var bottomView: UIView
    weak var zoomViewDelegate: ZoomViewDelegate?
    
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
        v.backgroundColor = .green
        
        
        NSLayoutConstraint.activate([
            v.bottomAnchor.constraint(equalTo: bottomAnchor),
            v.leadingAnchor.constraint(equalTo: frameLayoutGuide.leadingAnchor),
            v.trailingAnchor.constraint(equalTo: frameLayoutGuide.trailingAnchor),
            v.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        addObserver(self, forKeyPath: "contentOffset", context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let scrollView = object as? UIScrollView else { return }
        updateState(scrollView)
    }
    
    deinit {
        removeObserver(self, forKeyPath: "contentOffset")
    }
    
    required init?(coder: NSCoder) {
        index = 0
        bottomView = UIView()
        super.init(coder: coder)
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

        contentInset = UIEdgeInsets(top: top, left: left, bottom: top, right: left)
    }
    
    func updateState(_ scrollView: UIScrollView) {
                
        allowScroll = scrollView.zoomScale == 1

        if scrollView.contentOffset.y > 10 && scrollView.zoomScale == 1 {
            allowScroll = true
//                compresView(by: 0)
            scrollView.pinchGestureRecognizer?.isEnabled = false
        } else {
            scrollView.pinchGestureRecognizer?.isEnabled = true
        }
        
        if allowScroll {
            let contentHeight = scrollView.contentSize.height
            let scrollViewHeight = scrollView.bounds.size.height
            let offset = scrollView.contentOffset.y
            let percentage = (offset / (contentHeight - scrollViewHeight)) * 100
            
            if !isAnimating {
                if offset < 0 {
                    let nrom = normalize(from: 0, to: scrollView.frame.size.height, by: abs(offset))
                    let nrom2 = normalize(from: 0, to: 0.2, by: nrom)
                    zoomViewDelegate?.fadeProgress(val: 1 - nrom2)
                } else {
                    zoomViewDelegate?.fadeProgress(val: 1)
                }
            }
            
            if percentage < 1, !isAnimating, (scrollView.isTracking || lastInset < 0) {
//                    let norm = normalize(from: 0, to: 20, by: abs(percentage))
//                    let scale = CGFloat(1 - norm)
//                    scrollView.alpha = scale
//                    compresView(by: percentage)
            }
            
        
            if wasTracking, percentage < -10, !scrollView.isTracking {
                isAnimating = true
                let ogFram = scrollView.frame.origin
                DispatchQueue.main.async {
                    withAnimation(.linear(duration: 0.2)) {
                        self.zoomViewDelegate?.fadeProgress(val: 0)
                    }
                    UIView.animate(withDuration: 0.2, animations: {
                        scrollView.frame.origin = CGPoint(x: ogFram.x, y: scrollView.frame.size.height)
                    }) { _ in
                        self.zoomViewDelegate?.onDismiss()
                        
//                        //TEMP
//                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
//                            scrollView.frame.origin = ogFram
//                            self.zoomViewDelegate?.fadeProgress(val: 1)
//                            self.isAnimating = false
//                        }
                    }
                }
            }
        
            wasTracking = scrollView.isTracking
        }
    }
    
}


//func repeatOnMainThread(times: Int, interval: Double, action: @escaping (Int) -> Void) {
//    guard times > 0 else { return }
//    DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
//        action()
//        self.repeatOnMainThread(times: times - 1, interval: interval, action: action)
//    }
//}
