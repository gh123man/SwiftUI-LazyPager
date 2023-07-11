# LazyPager

A Lazy loaded, Zooming, Panning, and gesture dismissable pager view for SwiftUI. 

The goal with this library is to expose a simple SwiftUI interface for a flued and seamless content viewer.

[![Watch the video](/media/example.mov)](/media/example.mov)

# Usage

```swift 

 @State var data = [ ... ]
    
    @State var show = true
    @State var opacity: CGFloat = 1
    @State var index = 0

    var body: some View {
        Button("Open") {
            show.toggle()
        }
        .fullScreenCover(isPresented: $show) {
            LazyPager(data: data, page: $index) { data in
                Image(data)
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
        }
        .ignoresSafeArea()
    }
```

# Features

- All content is lazy loaded. By default content is pre-loaded 3 elements ahead and behind the current index. 
- Display any kind of content - not just images! 
- Lazy loaded views are disposed when they are outside of the pre-load frame to conserve resources. 
- Enable zooming and panning with `.zoomable(min: CGFloat, max: CGFloat)`
- Double tap to zoom is also supported.
- Works with `.ignoresSafeArea()` (or not) to get a true full screen view.
- Drag to dismiss is supported with `.onDismiss` - Supply a binding opacity value to control the background opacity during the transition. 
- Tap events are handled internally, so use `.onTap` to handle single taps (useful for hiding and showing UI)