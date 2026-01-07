import SwiftUI

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct AutoScrollView<Content: View, Item: Identifiable>: View {
    let items: [Item]
    let content: (Item) -> Content
    
    @State private var isAtBottom = true
    @State private var scrollViewHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    
    init(items: [Item], @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.content = content
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(items) { item in
                        content(item)
                            .id(item.id)
                    }
                }
                .background(GeometryReader { contentGeometry in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: contentGeometry.frame(in: .named("autoScrollView")).minY
                    )
                    .onAppear { contentHeight = contentGeometry.size.height }
                    .onChange(of: contentGeometry.size.height) { _, newValue in
                        contentHeight = newValue
                    }
                })
            }
            .coordinateSpace(name: "autoScrollView")
            .background(GeometryReader { scrollGeometry in
                Color.clear.onAppear { scrollViewHeight = scrollGeometry.size.height }
                    .onChange(of: scrollGeometry.size.height) { _, newValue in
                        scrollViewHeight = newValue
                    }
            })
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                let bottomOffset = contentHeight - scrollViewHeight + offset
                isAtBottom = bottomOffset <= 20 || contentHeight <= scrollViewHeight
            }
            .onChange(of: items.count) { _, _ in
                if isAtBottom, let lastItem = items.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastItem.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}
