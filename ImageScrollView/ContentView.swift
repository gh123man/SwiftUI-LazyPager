//
//  ContentView.swift
//  ImageScrollView
//
//  Created by Brian Floersch on 7/2/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        
        VStack {
            ZoomableScrollView {
                Image("winter8")
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



struct ZoomableScrollView<Content: View, BottomContent: View>: UIViewRepresentable {
    private var content: Content
    private var bottomContent: BottomContent
    
    init(@ViewBuilder content: () -> Content, @ViewBuilder bottomContent: () -> BottomContent) {
        self.content = content()
        self.bottomContent = bottomContent()
    }

    func makeUIView(context: Context) -> UIScrollView {
        // set up the UIScrollView
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator  // for viewForZooming(in:)
        scrollView.maximumZoomScale = 10
        scrollView.minimumZoomScale = 1
        scrollView.bouncesZoom = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .clear
        
        scrollView.layer.borderColor = CGColor.init(red: 0, green: 255, blue: 0, alpha: 1)
        scrollView.layer.borderWidth = 2
        
        // create a UIHostingController to hold our SwiftUI content
        guard let hostedView = context.coordinator.hostingController.view else {
            return scrollView
        }
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        hostedView.backgroundColor = .clear


        scrollView.addSubview(hostedView)

        // Bottom content
        guard let bottomContent = context.coordinator.bottomController.view else {
            return scrollView
        }

        bottomContent.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(bottomContent)
        context.coordinator.setupConstraints(scrollView)
        
        return scrollView
    }
    

    func makeCoordinator() -> Coordinator {
        return Coordinator(hostingController: UIHostingController(rootView: self.content),
                           bottomController: UIHostingController(rootView: self.bottomContent))
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.hostingController.rootView = self.content
//        assert(context.coordinator.hostingController.view.superview == uiView)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>
        var bottomController: UIHostingController<BottomContent>
        
        weak var scrollView: UIScrollView?
        var contentTopToFrame: NSLayoutConstraint!
        var contentTopToContent: NSLayoutConstraint!
        var contentBottomToFrame: NSLayoutConstraint!
//        var bottomContentHeight: NSLayoutConstraint!
        
        var allowScroll: Bool = true {
            didSet {
                if allowScroll {
                    contentTopToContent.isActive = true
                    contentTopToFrame.isActive = false
                    contentBottomToFrame.isActive = false
//                    bottomContentHeight.constant = 600
                    bottomController.view.isHidden = false
                    
                } else {
                    contentTopToContent.isActive = false
                    contentTopToFrame.isActive = true
                    contentBottomToFrame.isActive = true
//                    bottomContentHeight.constant = 0
                    bottomController.view.isHidden = true
                }
            }
        }
        
        init(hostingController: UIHostingController<Content>, bottomController: UIHostingController<BottomContent>) {
            self.hostingController = hostingController
            self.bottomController = bottomController
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController.view
        }
        
        func setupConstraints(_ scrollView: UIScrollView) {
            self.scrollView = scrollView
            
            NSLayoutConstraint.activate([
                hostingController.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
                hostingController.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
                hostingController.view.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
            ])
            
            contentTopToFrame = hostingController.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor)
            contentTopToContent = hostingController.view.topAnchor.constraint(equalTo: scrollView.topAnchor)
            contentBottomToFrame = hostingController.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor)
            
            
            NSLayoutConstraint.activate([
                bottomController.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                bottomController.view.topAnchor.constraint(equalTo: hostingController.view.bottomAnchor),
                bottomController.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                bottomController.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                bottomController.view.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            ])
            
            allowScroll = true
        }
        
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            updateState(scrollView)
        }
        
        func updateState(_ scrollView: UIScrollView) {
            
            allowScroll = scrollView.zoomScale == 1

            if scrollView.contentOffset.y > 10 && scrollView.zoomScale == 1 {
                allowScroll = true
                scrollView.pinchGestureRecognizer?.isEnabled = false
            } else {
                scrollView.pinchGestureRecognizer?.isEnabled = true
            }
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            guard let imageView = hostingController.view else {
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

