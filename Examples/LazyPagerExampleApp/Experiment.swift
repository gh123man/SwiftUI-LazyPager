//
//  Experiment.swift
//  LazyPagerExample
//
//  Created by Brian Floersch on 2/26/24.
//

import Foundation
import SwiftUI
import LazyPager


struct Const {
    static let animationDuration: Double = 1
}

struct Thumbnail: View {
    var name: String
    var namespace: Namespace.ID
    @Binding var selected: String?
    
    var body: some View {
        Color.clear
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
    @Binding var selected: String?
    var namespace: Namespace.ID
    @State var flip = true
    @Binding var page: Int
    var data: [String]
    
    var body: some View {
        Color.clear.overlay(
            ZStack {
                if flip {
                    Image(data[page])
                        .resizable()
                        .scaledToFit()
                        .matchedGeometryEffect(id: data[page],
                                               in: namespace,
                                               properties: .frame,
                                               anchor: .center)
                        .onAppear {
                            // This is ugly
                            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Int(Const.animationDuration))) {
                                flip = false
                            }
                        }
                } else {
                    LazyPager(data: data, page: $page) { name in
                        Image(name)
                            .resizable()
                            .scaledToFit()
                    }
                    .onTap {
                        flip = true
                        withAnimation(.linear(duration: Const.animationDuration)) {
                            selected = nil
                        }
                    }
                }
            }
        )
        .clipped()
        .transition(.scale(scale: 1))
        .matchedGeometryEffect(id: data[page] + "1", in: namespace, properties: .frame)
    }
}

struct Experiment: View {
    @Namespace private var animation
    @State private var isFlipped = false
    @State var selected: String? = nil
    @State var page = 0
    
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
                            Thumbnail(name: value, namespace: animation, selected: $selected)
                                .aspectRatio(1, contentMode: .fit)
                                .onTapGesture {
                                    page = data.firstIndex(of: value) ?? 0
                                    withAnimation(.linear(duration: Const.animationDuration)) {
                                        selected = value
                                    }
                                }
                        } else {
                            Rectangle()
                        }
                    }
                }
            }
            
            
            if selected != nil {
                Color.black
                FullScreenView(selected: $selected, namespace: animation, page: $page, data: data)
                    .onChange(of: page) { val in
                        selected = data[page]
                    }
            }
        }
    }
}

struct Experiment_Previews: PreviewProvider {
    static var previews: some View {
        Experiment()
    }
}
