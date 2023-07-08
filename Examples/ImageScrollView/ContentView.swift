//
//  ContentView.swift
//  ImageScrollView
//
//  Created by Brian Floersch on 7/2/23.
//

import SwiftUI
import LazyPager


struct BackgroundClearView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct ContentView: View {
    
    @State var data = [
        "winter1",
        "winter8",
        "birthday2",
        "winter1",
        "winter8",
    ]
    
    @State var data2 = Array((0...20))
    @State var show = true
    @State var opa: CGFloat = 1
    var body: some View {
        
        VStack {
            Button("Open") {
                show.toggle()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.red)
        .fullScreenCover(isPresented: $show) {
            ZStack {
                LazyPager(data: data, page: .constant(1)) { data in
                    //                Text("\(data)")
                    //                    .font(.title)
                    Image(data)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .onDismiss(backgroundOpacity: $opa) {
                    show = false
                }
            }
            .background(ClearFullScreenBackground())
            .onTapGesture {
                print("tap")
            }
//            .ignoresSafeArea()
            .background(.black.opacity(opa))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
