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
        uiViewController.viewWillLayoutSubviews()
    }
}

struct Thumbnail: View {
    var name: String
    var namespace: Namespace.ID
    
    var body: some View {
        Color.red
            .overlay(
            Image(name)
                .resizable()
                .scaledToFill()
                .matchedGeometryEffect(id: name, in: namespace)
                .frame(maxWidth: 160, maxHeight: 160)
        )
        .clipped()
        .transition(.identity)
        .matchedGeometryEffect(id: name + "1", in: namespace)
        .frame(maxWidth: 160, maxHeight: 160)
    }
}

struct FullScreenView: View {
    var name: String
    var namespace: Namespace.ID
    
    var body: some View {
        Color.red
            .overlay(
            
//            ZStack {
                Image(name)
                    .resizable()
                    .scaledToFit()
                    .matchedGeometryEffect(id: name,
                                           in: namespace,
                                           properties: .frame,
                                           anchor: .center)
//                SwiftUIViewWrapper {
//                    Image(name)
//                        .resizable()
//                        .scaledToFit()
//                        .matchedGeometryEffect(id: name,
//                                               in: namespace,
//                                               properties: .frame,
//                                               anchor: .center)
//                }
//            }
        )
        .clipped()
        .transition(.scale(scale: 1))
        .matchedGeometryEffect(id: name + "1", in: namespace, properties: .frame)
        .background(.clear)
    }
    
}

struct Experiment: View {
    @Namespace private var animation
    @State private var isFlipped = false
    @State var selected: String? = nil
    
    @State var data = [
        "nora1",
        "nora2",
        "nora3",
        "nora4",
        "nora5",
        "nora6",
    ]
    
    var body: some View {
        ZStack {
            
            ScrollView {
                LazyVGrid(columns:  [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]) {
                    ForEach(data, id: \.self) { value in
                        if selected != value {
                            Thumbnail(name: value, namespace: animation)
                                .aspectRatio(1, contentMode: .fit)
                                .onTapGesture {
                                    withAnimation {
                                        selected = value
                                    }
                                }
                        } else {
                            Rectangle()
                        }
                    }
                }
            }
            
            if let s = selected {
                FullScreenView(name: s, namespace: animation)
                .onTapGesture {
                    withAnimation {
                        selected = nil
                    }
                }
            }
        }
        
//        VStack {
//            if !isFlipped {
//                Thumbnail(name: "nora1", namespace: animation)
//            } else {
//                FullScreenView(name: "nora1", namespace: animation)
//            }
//            
//        }
//        .background(.clear)
//        .onTapGesture {
//            withAnimation {
//                isFlipped.toggle()
//            }
//       }
    }
}

struct Experiment_Previews: PreviewProvider {
    static var previews: some View {
        Experiment()
    }
}
