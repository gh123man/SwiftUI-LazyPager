//
//  ViewDataProvider.swift
//  
//
//  Created by Brian Floersch on 7/8/23.
//

import Foundation
import SwiftUI
import UIKit

public class ViewDataProvider<Content: View, DataCollecton: RandomAccessCollection, Element>: UIViewController, ViewLoader where DataCollecton.Index == Int, DataCollecton.Element == Element {
    
    var viewLoader: (Element) -> Content
    var data: DataCollecton
    var config: Config<Element>
    var pagerView: PagerView<Element, ViewDataProvider, Content>
    
    var dataCount: Int {
        return data.count
    }
    
    init(data: DataCollecton,
         page: Binding<Int>,
         config: Config<Element>,
         viewLoader: @escaping (Element) -> Content) {
        
        self.data = data
        self.viewLoader = viewLoader
        self.config = config
        self.pagerView = PagerView(page: page, config: config)

        super.init(nibName: nil, bundle: nil)
        self.pagerView.viewLoader = self
        
        pagerView.computeViewState()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func goToPage(_ page: Int, animated: Bool) {
        pagerView.goToPage(page, animated: animated)
    }
    
    func reloadViews() {
        pagerView.reloadViews()
        pagerView.computeViewState()
    }

    // MARK: ViewLoader
    
    func loadView(at index: Int) -> ZoomableView<Element, Content>? {
        guard let dta = data[safe: index] else { return nil }
        
        let hostingController = UIHostingController(rootView: viewLoader(dta))
        return ZoomableView(hostingController: hostingController, index: index, data: dta, config: config)
    }
    
    func updateHostedView(for zoomableView: ZoomableView<Element, Content>) {
        guard let dta = data[safe: zoomableView.index] else { return }
        
        zoomableView.hostingController.rootView = viewLoader(dta)
    }
    
    // MARK: UIViewController
    
    public override func loadView() {
        self.view = pagerView
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        pagerView.isRotating = true
        coordinator.animate(alongsideTransition: { context in }, completion: { context in
            self.pagerView.isRotating = false
            DispatchQueue.main.async {
                self.pagerView.goToPage(self.pagerView.currentIndex, animated: false)
            }
        })
    }
}

