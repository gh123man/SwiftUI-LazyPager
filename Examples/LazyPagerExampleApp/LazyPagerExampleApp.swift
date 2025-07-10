//
//  LazyPagerApp.swift
//  LazyPager
//
//  Created by Brian Floersch on 7/2/23.
//

import SwiftUI

@main
struct LazyPagerApp: App {
    @State var showFull = false
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                VStack(spacing: 20) {
                    NavigationLink(destination: SimpleExample()) {
                        Text("Simple Example")
                    }
                    NavigationLink(destination: EnvironmentExample()
                        .environmentObject(TextHolder(str: "hello world"))
                        .environment(\.customValue, "custom environment value")
                    ) {
                        Text("Environment Example")
                    }
                    NavigationLink(destination: AnimatedPagerControlsExample()) {
                        Text("Animated Pager Controls Example")
                    }
                    Button("full Test View horizontal") {
                        showFull.toggle()
                    }
                    NavigationLink(destination: FullTestView(direction: .vertical, show: .constant(true))) {
                        Text("Full Test View vertical")
                    }
                    NavigationLink(destination: VerticalMediaPager()) {
                        Text("Vertical media pager sample")
                    }
                }
            }
            .fullScreenCover(isPresented: $showFull) {
                FullTestView(direction: .horizontal, show: $showFull)
            }
        }
    }
}
