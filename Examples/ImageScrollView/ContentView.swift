//
//  ContentView.swift
//  ImageScrollView
//
//  Created by Brian Floersch on 7/2/23.
//

import SwiftUI
import LazyPager


//struct Foo: Equatable {
//    static func == (lhs: Foo, rhs: Foo) -> Bool {
//        return lhs.img == rhs.img
//    }
//
//    let id = UUID()
//    var img: String
//    var thign = barfoo()
//}

struct ContentView: View {
    
//    @State var data = [
//        Foo(img: "nora1"),
//        Foo(img: "nora2"),
//        Foo(img: "nora3"),
////        "nora4",
////        "nora5",
////        "nora6",
//    ]
    
    @State var data = [
        "nora1",
        "nora2",
        "nora3",
        "nora5",
        "nora6",
    ]
    
    @State var show = true
    @State var opacity: CGFloat = 1
    @State var index = 0
    var body: some View {
        Button("Open") {
            show.toggle()
        }
        .fullScreenCover(isPresented: $show) {
            ZStack {
                LazyPager(data: data, page: $index) { element in
                    Image(element)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .zoomable(min: 1, max: 5)
                .onDismiss(backgroundOpacity: $opacity) {
                    show = false
                }
                .onTap {
                    print("tap")
                }
                .background(.black.opacity(opacity))
                .background(ClearFullScreenBackground())
                .ignoresSafeArea()
                VStack {
//                    Text(data.description)
//                    Button("prepend") {
//                        data.insert("nora4", at: 0)
//                    }
                    Button("append") {
                        data.append("nora4")
                    }
                    Button("update") {
                        data[0] = "nora5"
                    }
                }
                .padding()
                .background(.white)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
