//
//  ZoomableView.swift
//  ImageScrollView
//
//  Created by Brian Floersch on 7/4/23.
//

import Foundation
import UIKit

class ZoomableView: UIScrollView, UIScrollViewDelegate {
    
    var trailingConstraint: NSLayoutConstraint?
    var leadingConstraint: NSLayoutConstraint?
    
    var index: Int
    init(view: UIView, index: Int) {
        self.index = index
        super.init(frame: .zero)
        
        translatesAutoresizingMaskIntoConstraints = false
        delegate = self
        maximumZoomScale = 10
        minimumZoomScale = 1
        bouncesZoom = true
        addSubview(view)
        
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.widthAnchor.constraint(equalTo: frameLayoutGuide.widthAnchor),
            view.heightAnchor.constraint(equalTo: frameLayoutGuide.heightAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        index = 0
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
    
}
