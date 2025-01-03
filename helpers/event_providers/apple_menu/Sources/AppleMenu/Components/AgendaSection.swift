import SwiftUI

public struct AgendaSection: View {
    public init() {}
    
    public var body: some View {
        VStack(spacing: 12) {
            // Agenda card with header
            Card {
                VStack(spacing: 12) {
                    // Agenda header
                    HStack {
                        Image(systemName: "list.bullet")
                            .foregroundColor(.gray)
                        Text("Agenda")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Agenda content
                    AgendaCard(showHeader: false)
                }
                .padding(12)
            }
            
            // System controls as separate card
            SystemControlsCard()
        }
    }
} 