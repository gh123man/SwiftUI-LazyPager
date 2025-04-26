//
//  EnvironmentExample.swift
//  LazyPagerExample
//
//  Created by Brian Floersch on 4/26/25.
//

import SwiftUI
import LazyPager

struct SubView: View {
    
    @EnvironmentObject var textHolder: TextHolder
    @Environment(\.customValue) var customValue
    
    var parentText: String
    var body: some View {
        VStack {
            Text("\(textHolder.str) \(parentText)")
                .font(.title)
                .padding()
            Text("Environment value: \(customValue)")
                .font(.subheadline)
                .padding()
        }
    }
}

struct EnvironmentExample: View {
    
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
        ZStack {
            LazyPager(data: data) { element in
                SubView(parentText: element)
            }
        }
    }
}

class TextHolder: ObservableObject {
    let str: String
    
    init(str: String) {
        self.str = str
    }
}

private struct CustomEnvironmentKey: EnvironmentKey {
    static let defaultValue: String = "default value"
}

extension EnvironmentValues {
    var customValue: String {
        get { self[CustomEnvironmentKey.self] }
        set { self[CustomEnvironmentKey.self] = newValue }
    }
}

#Preview {
    EnvironmentExample()
        .environmentObject(TextHolder(str: "hello world"))
        .environment(\.customValue, "custom environment value")
}
