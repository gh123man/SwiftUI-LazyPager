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
    var config: Config
    
    var scrollView: PagerView
    
    var contentTopToFrame: NSLayoutConstraint!
    var contentTopToContent: NSLayoutConstraint!
    var contentBottomToFrame: NSLayoutConstraint!
    
    
    init(data: [DataType],
         page: Binding<Int>,
         config: Config,
         viewLoader: @escaping (DataType) -> Content) {
        
        self.data = data
        self.viewLoader = viewLoader
        self.config = config
        self.scrollView = PagerView(page: page, config: config)
        self.scrollView.viewLoader = self
        
        scrollView.computeViewState()
    }
    
    func goToPage(_ page: Int) {
        scrollView.goToPage(page)
    }
}

extension ViewDataProvider: ViewLoader {
    func loadView(at index: Int) -> ZoomableView? {
        guard let dta = data[safe: index] else {
            return nil
        }
        
        guard let loadedContent = UIHostingController(rootView: viewLoader(dta)).view else {
            return nil
        }
        
        loadedContent.translatesAutoresizingMaskIntoConstraints = false
        loadedContent.backgroundColor = .clear
        
        return ZoomableView(view: loadedContent, index: index, config: config)
    }
}
