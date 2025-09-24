import SwiftUI

struct MiniCard<Destination: View>: View {
    let title: String
    let systemImage: String?
    let image: String?
    let destination: Destination
    
    init(
        title: String,
        systemImage: String? = nil,
        image: String? = nil,
        @ViewBuilder destination: () -> Destination
    ) {
        self.title = title
        self.systemImage = systemImage
        self.image = image
        self.destination = destination()
    }
    
    var body: some View {
        NavigationLink {
            destination
        } label: {
            ZStack {
                Rectangle()
                    .fill(.accent.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                
                VStack(spacing: 12) {
                    cardImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 35)
                        .clipShape(RoundedRectangle(cornerRadius: image != nil ? 12 : 0))
                        .foregroundStyle(.accent)
                    
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 100, height: 200)
                .foregroundStyle(.primary)
            }
            .frame(width: 150, height: 200)
        }
        .buttonStyle(.plain)
        .multilineTextAlignment(.center)
    }
    
    private var cardImage: Image {
        if let local = image {
            return Image(local)
        } else if let system = systemImage {
            return Image(systemName: system)
        } else {
            return Image(systemName: "globe")
        }
    }
}

struct TinyCard<Destination: View>: View {
    let title: String
    let systemImage: String?
    let image: String?
    let destination: Destination
    
    init(
        title: String,
        systemImage: String? = nil,
        image: String? = nil,
        @ViewBuilder destination: () -> Destination
    ) {
        self.title = title
        self.systemImage = systemImage
        self.image = image
        self.destination = destination()
    }
    
    var body: some View {
        NavigationLink {
            destination
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.accent.opacity(0.07))
                        .frame(width: 82, height: 70)
                    
                    cardImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: image != nil ? 12 : 0))
                        .foregroundStyle(.accent)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
            }
            .frame(width: 80)
        }
        .buttonStyle(.plain)
    }
    
    private var cardImage: Image {
        if let local = image {
            return Image(local)
        } else if let system = systemImage {
            return Image(systemName: system)
        } else {
            return Image(systemName: "globe")
        }
    }
}

struct LargeCard<Destination: View>: View {
    let title: String
    let subtitle: String?
    let systemImage: String?
    let image: String?
    let destination: Destination
    
    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String? = nil,
        image: String? = nil,
        @ViewBuilder destination: () -> Destination
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.image = image
        self.destination = destination()
    }
    
    var body: some View {
        NavigationLink {
            destination
        } label: {
            ZStack {
                Rectangle()
                    .fill(.accent.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                
                HStack(spacing: 20) {
                    cardImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: image != nil ? 12 : 0))
                        .foregroundStyle(.accent)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding()
                .foregroundStyle(.primary)
            }
            .frame(height: 120)
        }
        .buttonStyle(.plain)
    }
    
    private var cardImage: Image {
        if let local = image {
            return Image(local) // local asset
        } else if let system = systemImage {
            return Image(systemName: system) // SF Symbol
        } else {
            return Image(systemName: "globe") // fallback
        }
    }
}

struct LargeCardWithoutDestination: View {
    let title: String
    let subtitle: String?
    let systemImage: String?
    let image: String?
    
    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String? = nil,
        image: String? = nil,
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.image = image
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.accent.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 24))
            
            HStack(spacing: 20) {
                cardImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: image != nil ? 12 : 0))
                    .foregroundStyle(.accent)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding()
            .foregroundStyle(.primary)
        }
        .frame(height: 120)
    }
    
    private var cardImage: Image {
        if let local = image {
            return Image(local) // local asset
        } else if let system = systemImage {
            return Image(systemName: system) // SF Symbol
        } else {
            return Image(systemName: "globe") // fallback
        }
    }
}

