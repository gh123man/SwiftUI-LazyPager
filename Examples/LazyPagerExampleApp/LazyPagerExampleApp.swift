//
//  LazyPagerApp.swift
//  LazyPager
//
//  Created by Brian Floersch on 7/2/23.
//

import SwiftUI

@main
struct LazyPagerApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                VStack(spacing: 20) {
                    NavigationLink(destination: SimpleExample()) {
                        Text("Simple Example")
                    }
                    NavigationLink(destination: FullTestView(direction: .horizontal)) {
                        Text("Full Test View horizontal")
                    }
                    NavigationLink(destination: FullTestView(direction: .vertical)) {
                        Text("Full Test View vertical")
                    }
                    NavigationLink(destination: VerticalMediaPager()) {
                        Text("Vertical media pager sample")
                    }
                }
            }
        }
    }
}
