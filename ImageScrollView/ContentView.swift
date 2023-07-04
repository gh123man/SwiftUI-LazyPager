//
//  ContentView.swift
//  ImageScrollView
//
//  Created by Brian Floersch on 7/2/23.
//

import SwiftUI


struct ContentView: View {
    
    @State var data = [
        "winter1",
        "winter8",
        "birthday2"
    ]
    
    var body: some View {
        
        VStack {
            ZoomableScrollView(data: data) { data in
                Image(data)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } bottomContent: {
                Text("hi")
            }
        }
        .background(.red)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


struct ZoomableScrollView<Content: View, BottomContent: View, DataType>: UIViewRepresentable {
    private var viewLoader: (DataType) -> Content
    private var bottomContent: BottomContent
    private var data: [DataType]
    
    init(data: [DataType], content: @escaping (DataType) -> Content, @ViewBuilder bottomContent: () -> BottomContent) {
        self.data = data
        self.viewLoader = content
        self.bottomContent = bottomContent()
    }

    func makeUIView(context: Context) -> UIScrollView {
        return context.coordinator.setupScrollView()
    }
    

    func makeCoordinator() -> Coordinator {
        return Coordinator(data: data,
                           viewLoader: viewLoader,
                           bottomController: UIHostingController(rootView: self.bottomContent))
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
//        context.coordinator.hostingController.rootView = self.content
//        assert(context.coordinator.hostingController.view.superview == uiView)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UIScrollViewDelegate {
        private var viewLoader: (DataType) -> Content
        
        var data: [DataType]
        
        var scrollView = UIScrollView()
        
        var contentTopToFrame: NSLayoutConstraint!
        var contentTopToContent: NSLayoutConstraint!
        var contentBottomToFrame: NSLayoutConstraint!
        
        var currentView: UIView?
        var curretnIndex = 0
        
        init(data: [DataType], viewLoader: @escaping (DataType) -> Content, bottomController: UIHostingController<BottomContent>) {
            self.data = data
            self.viewLoader = viewLoader
        }

        func setupScrollView() -> UIScrollView {
            scrollView.delegate = self
            scrollView.showsVerticalScrollIndicator = false
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.backgroundColor = .clear
            scrollView.isPagingEnabled = true
            
            scrollView.layer.borderColor = CGColor.init(red: 0, green: 255, blue: 0, alpha: 1)
            scrollView.layer.borderWidth = 2
            
            loadView(at: 0)
            loadNext()
            return scrollView
        }
        
        func makeZommableView(view: UIView) -> UIView {
            let sv = UIScrollView()
            sv.translatesAutoresizingMaskIntoConstraints = false
            sv.delegate = self
            sv.maximumZoomScale = 10
            sv.minimumZoomScale = 1
            sv.bouncesZoom = true
            sv.addSubview(view)
            
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: sv.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: sv.trailingAnchor),
                view.widthAnchor.constraint(equalTo: sv.frameLayoutGuide.widthAnchor),
                view.heightAnchor.constraint(equalTo: sv.frameLayoutGuide.heightAnchor),
            ])
            return sv
        }
        
        func loadView(at index: Int) {
            guard let dta = data[safe: index] else {
                return
            }
            curretnIndex = index
            
            let loadedContent = UIHostingController(rootView: viewLoader(dta)).view!
            
            loadedContent.translatesAutoresizingMaskIntoConstraints = false
            loadedContent.backgroundColor = .clear
            
            let sv = makeZommableView(view: loadedContent)
            scrollView.addSubview(sv)
            
            NSLayoutConstraint.activate([
                
                sv.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
//                sv.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                sv.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
                sv.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
                
            ])
            
            currentView = sv
        }
        
        func loadNext() {
            guard let dta = data[safe: curretnIndex + 1] else {
                return
            }
            
            guard let currentView = currentView else {
                return
            }
            
            let loadedContent = UIHostingController(rootView: viewLoader(dta)).view!
            
            loadedContent.translatesAutoresizingMaskIntoConstraints = false
            loadedContent.backgroundColor = .clear
            
            let sv = makeZommableView(view: loadedContent)
            scrollView.addSubview(sv)
            
            NSLayoutConstraint.activate([
                sv.leadingAnchor.constraint(equalTo: currentView.trailingAnchor),
                sv.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                sv.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
                sv.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
            ])
            
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.subviews[0]
        }
        
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            let imageView = scrollView.subviews[0]
            
            let w: CGFloat = imageView.intrinsicContentSize.width * UIScreen.main.scale
            let h: CGFloat = imageView.intrinsicContentSize.height * UIScreen.main.scale


            let ratioW = imageView.frame.width / w
            let ratioH = imageView.frame.height / h

            let ratio = ratioW < ratioH ? ratioW : ratioH

            let newWidth = w*ratio
            let newHeight = h*ratio

            let left = 0.5 * (newWidth * scrollView.zoomScale > imageView.frame.width
                              ? (newWidth - imageView.frame.width)
                              : (scrollView.frame.width - imageView.frame.width))
            let top = 0.5 * (newHeight * scrollView.zoomScale > imageView.frame.height
                             ? (newHeight - imageView.frame.height)
                             : (scrollView.frame.height - imageView.frame.height))

            scrollView.contentInset = UIEdgeInsets(top: top, left: left, bottom: top, right: left)

//            updateState(scrollView)
        }
    }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
