import SwiftUI

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct AutoScrollView<Content: View, Item: Identifiable>: View {
    let items: [Item]
    let isAutoScrollEnabled: Bool
    let content: (Item) -> Content

    @State private var scrollViewHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0

    init(items: [Item], isAutoScrollEnabled: Bool = true, @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.isAutoScrollEnabled = isAutoScrollEnabled
        self.content = content
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(items) { item in
                        content(item)
                    }
                    Color.clear
                        .frame(height: 60)
                        .id("bottom-anchor")
                }
            }
            .onChange(of: items.count) { _, _ in
                if isAutoScrollEnabled {
                    withAnimation {
                        proxy.scrollTo("bottom-anchor", anchor: .bottom)
                    }
                }
            }
        }
    }
}
