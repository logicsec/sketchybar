import SwiftUI

public struct AgendaCard: View {
    @State private var tasks = [
        "Yet another agenda file",
        "TODO insert important task here^^",
        "Pending",
        "TODO バイデン・ブラスト！",
        "TODO 日本語学習",
        "TODO RUSTプログラミング言語を習う",
        "TODO 数学を学習",
        "TODO finish [the pragmatic programmer] book",
        "TODO get the bootloader to work"
    ]
    
    let showHeader: Bool
    
    public init(showHeader: Bool = true) {
        self.showHeader = showHeader
    }
    
    public var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(tasks, id: \.self) { task in
                        Text(task)
                            .foregroundColor(task.hasPrefix("TODO") ? Color(red: 0.8, green: 0.8, blue: 0.6) : .gray)
                            .font(.system(size: 12))
                    }
                }
            }
            .padding(12)
        }
    }
} 