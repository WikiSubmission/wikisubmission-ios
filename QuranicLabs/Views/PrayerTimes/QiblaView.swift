import SwiftUI

struct QiblaView: View {
    @StateObject private var qiblaManager = QiblaManager()
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 50) {
                    StatusCardsView(qiblaManager: qiblaManager)

                    CurrentHeadingView(heading: qiblaManager.currentHeading, color: qiblaManager.headingColor, qiblaManager: qiblaManager)
                    
                    DirectionalAidView(qiblaManager: qiblaManager)
                }
                .padding()
            }
        }
        .navigationTitle("Qibla")
        .onAppear {
            qiblaManager.start()
        }
        .onDisappear {
            qiblaManager.stop()
        }
    }
}

private struct DirectionalAidView: View {
    @ObservedObject var qiblaManager: QiblaManager
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let centerX = width / 2
            
            // Calculate difference and direction
            let diff = qiblaManager.directionDifference
            // Determine if heading is clockwise or counterclockwise relative to Qibla
            let offsetDirection = qiblaManager.offsetDirection
            
            // Map difference (0 to 180) to horizontal offset (-centerX to centerX)
            let maxOffset = centerX - 15 // padding for marker radius
            let normalizedDiff = min(diff, 180)
            let offsetX = CGFloat(normalizedDiff / 180) * maxOffset * (offsetDirection == .clockwise ? 1 : -1)
            
            VStack {
                ZStack(alignment: .center) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 20)
                    
                    // Center Qibla marker
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 3, height: 30)
                        .offset(x: 0)
                    
                    // User heading marker
                    Circle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                        .offset(x: offsetX)
                        .animation(.easeInOut(duration: 0.3), value: offsetX)
                }
                
                if Int(diff) > 10 {
                    HStack(spacing: 8) {
                        Text("\(Int(diff))° off")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        if offsetDirection == .clockwise {
                            Text("Rotate Right")
                                .font(.footnote)
                                .foregroundColor(.orange)
                        } else if offsetDirection == .counterclockwise {
                            Text("Rotate Left")
                                .font(.footnote)
                                .foregroundColor(.orange)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                }
            }
        }
        .frame(height: 60)
        .padding(.horizontal)
    }
}

private struct StatusCardsView: View {
    @ObservedObject var qiblaManager: QiblaManager
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack {
            HStack {
                Text("PREVIEW MODE")
                Spacer()
                Button {
                    let subject = "Re: Qibla Feature".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Re: Qibla Feature"
                    if let url = URL(string: "mailto:\(Info.contactEmail)?subject=\(subject)"),
                       UIApplication.shared.canOpenURL(url) {
                        openURL(url)
                    }
                } label: {
                    Label("Send feedback", systemImage: "envelope")
                        .foregroundStyle(.accent)
                }
            }
            .font(.footnote)
            .fontWeight(.light)
            .foregroundStyle(.secondary)
            LargeCardWithoutDestination(title: "Qibla at \(Int(qiblaManager.qiblaDirection))° (\(qiblaManager.qiblaDirectionString))", systemImage: "safari.fill")
        }
    }
}

private struct CurrentHeadingView: View {
    let heading: Double
    let color: Color
    
    @ObservedObject var qiblaManager: QiblaManager

    var body: some View {
        VStack(spacing: 12) {
            Text("\(Int(heading))°")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
            
            Text(qiblaManager.statusText)
                .font(.headline)
                .fontWeight(.bold)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(color.opacity(0.2))
                .foregroundColor(color)
                .clipShape(Capsule())
                .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
        }
    }
}

#Preview {
    QiblaView()
}
