# LazyPager for SwiftUI

A Lazy loaded, panning, zooming, and gesture dismissable pager view for SwiftUI. 

The goal with this library is to expose a simple SwiftUI interface for a fluid and seamless content viewer.

<p align="center">
  <img src="https://github.com/gh123man/LazyPager/assets/959778/a82da8c3-9d65-4782-8fd7-40cc598e16da" alt="animated" />
</p>

## Highlights 

- Buttery smooth scrolling/panning/zooming
- Swipe down to dismiss 
- Double tap to zoom
- Lazy loading


# Usage

```swift 
@State var data = [ ... ]
@State var show = true
@State var opacity: CGFloat = 1 // Dismiss gesture opacity 
@State var index = 0

var body: some View {
    Button("Open") {
        show.toggle()
    }
    .fullScreenCover(isPresented: $show) {

        // Provide any list of data and bind to an index
        LazyPager(data: data, page: $index) { data in

            // Supports any kind of view - not only images
            Image(data)
                .resizable()
                .aspectRatio(contentMode: .fit)
        }

        // Make the content zoomable
        .zoomable(min: 1, max: 5)

        // Enable the swipe to dismiss gesture
        .onDismiss(backgroundOpacity: $opacity) {
            show = false
        }

        // Handle single tap gestures
        .onTap {
            print("tap")
        }

        // Set the background color with the drag opacity control
        .background(.black.opacity(opacity))

        // A special included modifier to help make fullScreenCover transparent
        .background(ClearFullScreenBackground())
    }
    // Works with safe areas or ignored safe areas
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
- Use `.settings` to [modify advanced settings](https://github.com/gh123man/LazyPager/blob/master/Sources/LazyPager/LazyPager.swift#L17)
