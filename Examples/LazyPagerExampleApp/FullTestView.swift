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
    let idx: Int
}

struct FullTestView: View {
    
    var direction: Direction
    @State var data = [
        Foo(img: "nora1", idx: 0),
        Foo(img: "nora2", idx: 1),
        Foo(img: "nora3", idx: 2),
        Foo(img: "nora4", idx: 3),
        Foo(img: "nora5", idx: 4),
        Foo(img: "nora6", idx: 5),
        Foo(img: "nora1", idx: 6),
        Foo(img: "nora2", idx: 7),
        Foo(img: "nora3", idx: 8),
        Foo(img: "nora4", idx: 9),
        Foo(img: "nora5", idx: 10),
        Foo(img: "nora6", idx: 11),
    ]
    
    @Binding var show: Bool
    @State var opacity: CGFloat = 1
    @State var index = 0
    @State var loadPager = false
    
    var body: some View {
        VStack {
            LazyPager(data: data, page: $index, direction: direction) { element in
                ZStack {
                    Image(element.img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    VStack {
                        Text("\(index) \(element.idx) \(data.count - 1)")
                            .foregroundColor(.black)
                            .background(.white)
                    }
                }
            }
            .zoomable(min: 1, max: 5)
            .onDismiss(backgroundOpacity: $opacity) {
                show = false
            }
            .onTap {
                print("tap")
            }
            .shouldLoadMore(on: .lastElement(minus: 2)) {
                data.append(Foo(img: "nora4", idx: data.count))
            }
            .overscroll { position in
                if position == .beginning {
                    print("Swiped past beginning")
                } else {
                    print("Swiped past end")
                }
            }
            .background(.black.opacity(opacity))
            .background(ClearFullScreenBackground())
            .ignoresSafeArea()
            VStack {
                HStack(spacing: 30) {
                    Button("-") {
                        index -= 1
                    }
                    VStack(spacing: 10) {
                        Button("append") {
                            data.append(Foo(img: "nora4", idx: data.count + 1))
                        }
                        Button("replace") {
                            data[0] = Foo(img: "nora4", idx: data.count + 1)
                        }
                        Button("update") {
                            data[0].img = "nora5"
                        }
                    }
                    VStack(spacing: 10) {
                        Button("del first") {
                            data.remove(at: 0)
                            index -= 1
                        }
                        Button("del last") {
                            data.remove(at: data.count - 1)
                        }
                        Button("jmp") {
                            index = 10
                        }
                    }
                    Button("+") {
                        index += 1
                    }
                }
                
            }
            .frame(maxWidth: .infinity)
            .background(.white)
        }
    }
}

struct FullTestView_Previews: PreviewProvider {
    static var previews: some View {
        FullTestView(direction: .horizontal, show: .constant(true))
    }
}
