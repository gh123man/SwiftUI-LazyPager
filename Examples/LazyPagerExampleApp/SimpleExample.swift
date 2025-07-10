import SwiftUI
import LazyPager


struct SimpleExample: View {
    
    @State var data = [
        "nora1",
        "nora2",
        "nora3",
        "nora4",
        "nora5",
        "nora6",
    ]
    
    @State var show = false
    
    var body: some View {
        LazyPager(data: data) { element in
            Image(element)
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
        .onDismiss {
        }
    }
}

struct SimpleExample_Previews: PreviewProvider {
    static var previews: some View {
        SimpleExample()
    }
}
