//
//  File.swift
//  
//
//  Created by Brian Floersch on 7/8/23.
//

import Foundation
import SwiftUI
import UIKit

public class ViewDataProvider<Content: View, Element: Equatable>: ViewLoader {
    private var viewLoader: (Element) -> Content
    
    var data: [Element]
    var config: Config
    
    var pagerView: PagerView<Element, ViewDataProvider>
    
    var contentTopToFrame: NSLayoutConstraint!
    var contentTopToContent: NSLayoutConstraint!
    var contentBottomToFrame: NSLayoutConstraint!
    
    
    init(data: [Element],
         page: Binding<Int>,
         config: Config,
         viewLoader: @escaping (Element) -> Content) {
        
        self.data = data
        self.viewLoader = viewLoader
        self.config = config
        self.pagerView = PagerView(page: page, config: config)
        self.pagerView.viewLoader = self
        
        pagerView.computeViewState()
    }
    
    func goToPage(_ page: Int) {
        pagerView.goToPage(page)
    }
    
    func reloadViews() {
        pagerView.reloadViews()
        pagerView.computeViewState()
    }
//}
//
//extension ViewDataProvider: ViewLoader {
    func loadView(at index: Int) -> ZoomableView<Element>? {
        guard let dta = data[safe: index] else { return nil }
        guard let loadedContent = UIHostingController(rootView: viewLoader(dta)).view else { return nil }
        
        loadedContent.translatesAutoresizingMaskIntoConstraints = false
        loadedContent.backgroundColor = .clear
        
        return ZoomableView(view: loadedContent, index: index, data: dta, config: config)
    }
    
    func replaceViewIfNeeded(for zoomableView: ZoomableView<Element>) {
        if data[zoomableView.index] == zoomableView.data { return }
        
        guard let dta = data[safe: zoomableView.index] else { return }
        guard let loadedContent = UIHostingController(rootView: viewLoader(dta)).view else { return }
        
        loadedContent.translatesAutoresizingMaskIntoConstraints = false
        loadedContent.backgroundColor = .clear
        
        zoomableView.replace(view: loadedContent)
    }
}
