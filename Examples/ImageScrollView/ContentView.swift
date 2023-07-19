//
//  ContentView.swift
//  LazyPager
//
//  Created by Brian Floersch on 7/2/23.
//

import SwiftUI
import LazyPager


struct Foo {
    let id = UUID()
    var img: String
}

struct ContentView: View {
    
    @State var data = [
        Foo(img: "nora1"),
        Foo(img: "nora2"),
        Foo(img: "nora3"),
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
                    Image(element.img)
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
                .shouldLoadMore(on: .lastElement(minus: 2)) {
                    data.append(Foo(img: "nora4"))
                }
                .background(.black.opacity(opacity))
                .background(ClearFullScreenBackground())
                .ignoresSafeArea()
                VStack {
                    Button("append") {
                        data.append(Foo(img: "nora4"))
                    }
                    Button("replace") {
                        data[0] = Foo(img: "nora4")
                    }
                    Button("update") {
                        data[0].img = "nora5"
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
