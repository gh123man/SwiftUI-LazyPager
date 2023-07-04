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
        
//        // create a UIHostingController to hold our SwiftUI content
//        guard let hostedView = context.coordinator.hostingController.view else {
//            return scrollView
//        }
//        hostedView.translatesAutoresizingMaskIntoConstraints = false
//        hostedView.backgroundColor = .clear
//
//        scrollView.addSubview(hostedView)
//
//        // Bottom content
//        guard let bottomContent = context.coordinator.bottomController.view else {
//            return scrollView
//        }
//
//        bottomContent.translatesAutoresizingMaskIntoConstraints = false
//
//        scrollView.addSubview(bottomContent)
//        context.coordinator.setupConstraints(scrollView)
//
//        return scrollView
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
//        var hostingController: UIHostingController<Content>
        var bottomController: UIHostingController<BottomContent>
        
        var data: [DataType]
        
        var scrollView = UIScrollView()
        var contentView = UIView()
        
        var contentTopToFrame: NSLayoutConstraint!
        var contentTopToContent: NSLayoutConstraint!
        var contentBottomToFrame: NSLayoutConstraint!
        
        var currentView: UIView?
        var curretnIndex = 0
        
        var allowScroll: Bool = true {
            didSet {
//                if allowScroll {
//                    contentTopToContent.isActive = true
//                    contentTopToFrame.isActive = false
//                    contentBottomToFrame.isActive = false
//                    bottomController.view.isHidden = false
//                } else {
//                    contentTopToContent.isActive = false
//                    contentTopToFrame.isActive = true
//                    contentBottomToFrame.isActive = true
//                    bottomController.view.isHidden = true
//                }
            }
        }
        
        init(data: [DataType], viewLoader: @escaping (DataType) -> Content, bottomController: UIHostingController<BottomContent>) {
            self.data = data
            self.viewLoader = viewLoader
//            self.hostingController = hostingController
            self.bottomController = bottomController
        }

        
        func setupScrollView() -> UIScrollView {
            scrollView.delegate = self
            scrollView.maximumZoomScale = 10
            scrollView.minimumZoomScale = 1
            scrollView.bouncesZoom = true
            scrollView.showsVerticalScrollIndicator = false
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.backgroundColor = .clear
            scrollView.isPagingEnabled = true
            
            scrollView.layer.borderColor = CGColor.init(red: 0, green: 255, blue: 0, alpha: 1)
            scrollView.layer.borderWidth = 2
            
            contentView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(contentView)
            
            NSLayoutConstraint.activate([
                contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            ])
            
            loadView(at: 0)
            loadNext()
            return scrollView
        }
        
        func loadView(at index: Int) {
            guard let dta = data[safe: index] else {
                return
            }
            curretnIndex = index
            
            let loadedContent = UIHostingController(rootView: viewLoader(dta)).view!
            
            loadedContent.translatesAutoresizingMaskIntoConstraints = false
            loadedContent.backgroundColor = .clear
            contentView.addSubview(loadedContent)
            
            NSLayoutConstraint.activate([
                loadedContent.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//                loadedContent.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                loadedContent.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
                loadedContent.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
            ])
            
            currentView = loadedContent
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
            contentView.addSubview(loadedContent)
            
            NSLayoutConstraint.activate([
                loadedContent.leadingAnchor.constraint(equalTo: currentView.trailingAnchor),
                loadedContent.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                loadedContent.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
                loadedContent.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
            ])
            
        }
        
        func setupConstraints() {
            
//            NSLayoutConstraint.activate([
//                hostingController.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
//                hostingController.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
//                hostingController.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
//                hostingController.view.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
//            ])
//
//            contentTopToFrame = hostingController.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor)
//            contentTopToContent = hostingController.view.topAnchor.constraint(equalTo: scrollView.topAnchor)
//            contentBottomToFrame = hostingController.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor)
//
//
//            NSLayoutConstraint.activate([
//                bottomController.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
//                bottomController.view.topAnchor.constraint(equalTo: hostingController.view.bottomAnchor),
//                bottomController.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
//                bottomController.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
//                bottomController.view.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
//            ])
//
//            allowScroll = true
        }
        
        func loadData() {
            
        }
        
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            updateState(scrollView)
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return currentView
        }
        
        func updateState(_ scrollView: UIScrollView) {
            
//            allowScroll = scrollView.zoomScale == 1
//
//            if scrollView.contentOffset.y > 10 && scrollView.zoomScale == 1 {
//                allowScroll = true
//                scrollView.pinchGestureRecognizer?.isEnabled = false
//            } else {
//                scrollView.pinchGestureRecognizer?.isEnabled = true
//            }
        }
        
        func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
            
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            guard let imageView = currentView else {
                return
            }
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

            updateState(scrollView)
        }
    }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
