import SwiftUI
import LazyPager


struct AnimatedPagerControlsExample: View {
    
    @State var data = [
        "nora1",
        "nora2",
        "nora3",
        "nora4",
        "nora5",
        "nora6",
    ]
    
    @State var show = false
    @State var index = 0
    
    var body: some View {
        VStack {
            LazyPager(data: data, page: $index) { element in
                Image(element)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            HStack(spacing: 20) {
                Button("First") {
                    withAnimation {
                        index = 0
                    }
                }
                Button("Prev") {
                    withAnimation {
                        if index > 0 {
                            index -= 1
                        }
                    }
                    
                }
                Button("Next") {
                    withAnimation {
                        if index < data.count {
                            index += 1
                        }
                    }
                    
                }
                Button("Last") {
                    withAnimation {
                        index = data.count - 1
                    }
                }
            }
        }
    }
}

struct AnimatedPagerControlsExample_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedPagerControlsExample()
    }
}
