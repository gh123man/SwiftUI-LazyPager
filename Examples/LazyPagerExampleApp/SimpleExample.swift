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
    
    var body: some View {
        LazyPager(data: data) { element in
            Image(element)
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}

struct SimpleExample_Previews: PreviewProvider {
    static var previews: some View {
        SimpleExample()
    }
}
