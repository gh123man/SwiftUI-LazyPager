//
//  File.swift
//  
//
//  Created by Brian Floersch on 7/8/23.
//

import Foundation
import SwiftUI
import UIKit

public class ViewDataProvider<Content: View, DataType> {
    private var viewLoader: (DataType) -> Content
    
    var data: [DataType]
    var backgroundOpacity: Binding<CGFloat>?
    var dismissCallback: (() -> ())?
    var tapCallback: (() -> ())?
    var scrollView: PagerView
    var contentTopToFrame: NSLayoutConstraint!
    var contentTopToContent: NSLayoutConstraint!
    var contentBottomToFrame: NSLayoutConstraint!
    
    
    init(data: [DataType],
         page: Binding<Int>,
         backgroundOpacity: Binding<CGFloat>?,
         dismissCallback: (() -> ())?,
         tapCallback: (() -> ())?,
         viewLoader: @escaping (DataType) -> Content) {
        
        self.data = data
        self.viewLoader = viewLoader
        self.scrollView = PagerView(page: page)
        self.scrollView.viewLoader = self
        self.scrollView.zoomViewDelegate = self
        self.backgroundOpacity = backgroundOpacity
        self.dismissCallback = dismissCallback
        self.tapCallback = tapCallback
        
        scrollView.computeViewState()
    }
    
    func goToPage(_ page: Int) {
        scrollView.goToPage(page)
    }
}

extension ViewDataProvider: ZoomViewDelegate {
    func fadeProgress(val: CGFloat) {
        backgroundOpacity?.wrappedValue = val
    }
    
    func didTap() {
        tapCallback?()
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

extension ViewDataProvider: ViewLoader {
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
