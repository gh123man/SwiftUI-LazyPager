//
//  File.swift
//  
//
//  Created by Brian Floersch on 7/8/23.
//

import Foundation
import SwiftUI
import UIKit

public class ViewDataProvider<Content: View, DataCollecton: RandomAccessCollection, Element>: ViewLoader where DataCollecton.Index == Int, DataCollecton.Element == Element {
    private var viewLoader: (Element) -> Content
    
    var data: DataCollecton
    var config: Config
    
    var pagerView: PagerView<Element, ViewDataProvider, Content>
    
    var contentTopToFrame: NSLayoutConstraint!
    var contentTopToContent: NSLayoutConstraint!
    var contentBottomToFrame: NSLayoutConstraint!
    
    var dataCount: Int {
        return data.count
    }
    
    
    init(data: DataCollecton,
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

    //MARK: ViewLoader
    
    func loadView(at index: Int) -> ZoomableView<Element, Content>? {
        guard let dta = data[safe: index] else { return nil }
        let hostingController = UIHostingController(rootView: viewLoader(dta))
        return ZoomableView(hostingController: hostingController, index: index, data: dta, config: config)
    }
    
    func updateHostedView(for zoomableView: ZoomableView<Element, Content>) {
        guard let dta = data[safe: zoomableView.index] else { return }
        zoomableView.hostingController.rootView = viewLoader(dta)
    }
}
