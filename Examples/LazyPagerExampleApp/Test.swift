//
//  Test.swift
//  LazyPagerExample
//
//  Created by Brian Floersch on 3/2/24.
//

import Foundation
import SwiftUI

struct SwiftUIViewWrapper<Content: View>: UIViewControllerRepresentable {
    @ViewBuilder var swiftUIView: Content
    
    func makeUIViewController(context: Context) -> UIHostingController<Content> {
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        return hostingController
    }
    
    func updateUIViewController(_ uiViewController: UIHostingController<Content>, context: Context) {
        uiViewController.viewWillLayoutSubviews()
    }
}
