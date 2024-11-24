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
        VStack {
            Button("Show") {
                show.toggle()
            }
        }
        .fullScreenCover(isPresented: $show) {
            LazyPager(data: data) { element in
                VStack {
                    Image(element)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .onTapGesture {
                            print("tap image")
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    show.toggle()
                    print("tap background")
                }
            }
        }
    }
}

struct SimpleExample_Previews: PreviewProvider {
    static var previews: some View {
        SimpleExample()
    }
}
