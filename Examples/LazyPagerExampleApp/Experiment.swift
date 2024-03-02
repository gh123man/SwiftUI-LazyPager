//
//  Experiment.swift
//  LazyPagerExample
//
//  Created by Brian Floersch on 2/26/24.
//

import Foundation
import SwiftUI
import LazyPager



struct SwiftUIViewWrapper<Content: View>: UIViewControllerRepresentable {
    @ViewBuilder var swiftUIView: Content
    
    func makeUIViewController(context: Context) -> UIHostingController<Content> {
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        return hostingController
    }
    
    func updateUIViewController(_ uiViewController: UIHostingController<Content>, context: Context) {
    }
}

struct Experiment: View {
    @Namespace private var animation
    @State private var isFlipped = false
    
    var body: some View {
        VStack {
            if !isFlipped {
                    Color.clear.overlay(
                        Image("nora1")
                            .resizable()
                            .scaledToFill()
                            .matchedGeometryEffect(id: "nora1", in: animation)
                            .frame(maxWidth: 160, maxHeight: 160)
                    )
                    .clipped()
                    .transition(.scale(scale: 1))
                    .matchedGeometryEffect(id: "nora11", in: animation)
                    .frame(maxWidth: 160, maxHeight: 160)
                    
                    
                
            } else {
                Color.clear.overlay(
                        Image("nora1")
                            .resizable()
                            .scaledToFit()
                            .matchedGeometryEffect(id: "nora1",
                                                   in: animation,
                                                   properties: .frame,
                                                   anchor: .center)
                            
                    )
                .clipped()
                .transition(.scale(scale: 1))
                .matchedGeometryEffect(id: "nora11", in: animation, properties: .frame)
                .background(.clear)
            }
            
        }
        .background(.clear)
        .onTapGesture {
            withAnimation {
                isFlipped.toggle()
            }
       }
    }
}

struct Experiment_Previews: PreviewProvider {
    static var previews: some View {
        Experiment()
    }
}
