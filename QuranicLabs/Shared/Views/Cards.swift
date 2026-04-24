import SwiftUI

struct Card: View {
    var title: String
    var options: CardOptions? = nil

    @ViewBuilder
    private var cardImage: some View {
        let color = options?.style.accent ?? .accentColor
        let size: CGFloat = 32

        if let image = options?.image {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundStyle(color)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
        } else if let systemImage = options?.systemImage {
            if systemImage == "progressview" {
                ProgressView()
                    .frame(width: size, height: size)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: DS.Radius.md)
                        .fill(color.opacity(0.12))
                        .frame(width: size, height: size)
                    Image(systemName: systemImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size * 0.52, height: size * 0.52)
                        .foregroundStyle(color)
                }
            }
        }
    }

    var body: some View {
        let style = options?.style ?? .default

        let content = ZStack {
            Rectangle()
                .fill(style.background)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg))

            HStack(alignment: options?.imageAlignment ?? .center, spacing: 20) {
                Group {
                    cardImage
                }
                .offset(y: options?.imageAlignment == .top ? 8 : 0)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(DS.Typography.eyebrowLG)
                        .fontWeight(.semibold)
                        .foregroundColor(style.foreground)
                        .multilineTextAlignment(.leading)
                        .pushToLeft()

                    if let subtitle = options?.subtitle {
                        Text(.init(subtitle))
                            .font(DS.Typography.eyebrow)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .pushToLeft()
                    }

                    // Optional child content below subtitle
                    if let extraContent = options?.content {
                        extraContent
                            .padding(.top, 4)
                    }
                }

                Group {
                    if options?.showChevron == true {
                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(style.chevron)

                    }
                }
                .offset(y: options?.imageAlignment == .top ? 8 : 0)
            }
            .padding(.vertical, 12)
            .padding(.horizontal)
        }
            .textSelection(.enabled)

        switch options?.intent {
        case .action(let action):
            content.onTapGesture(perform: action)

        case .destination(let destination):
            NavigationLink(destination: destination) {
                content
            }
            .buttonStyle(.plain)

        case nil:
            content
        }
    }
}

struct CardOptions {
    let subtitle: String?
    let image: String?
    let systemImage: String?
    let imageAlignment: VerticalAlignment?
    let intent: CardIntent?
    let showChevron: Bool?
    let style: CardStyle
    let content: AnyView?

    init(
        subtitle: String? = nil,
        image: String? = nil,
        systemImage: String? = nil,
        imageAlignment: VerticalAlignment? = nil,
        intent: CardIntent? = nil,
        showChevron: Bool? = nil,
        style: CardStyle = .default,
        content: AnyView? = nil
    ) {
        self.subtitle = subtitle
        self.image = image
        self.systemImage = systemImage
        self.imageAlignment = imageAlignment
        self.intent = intent
        self.showChevron = showChevron
        self.style = style
        self.content = content
    }


    static func action(
        subtitle: String? = nil,
        image: String? = nil,
        systemImage: String? = nil,
        imageAlignment: VerticalAlignment? = nil,
        showChevron: Bool? = nil,
        style: CardStyle = .default,
        @ViewBuilder content: () -> some View = { EmptyView() }, // default closure
        _ action: @escaping () -> Void
    ) -> CardOptions {
        .init(
            subtitle: subtitle,
            image: image,
            systemImage: systemImage,
            imageAlignment: imageAlignment,
            intent: .action(action),
            showChevron: showChevron,
            style: style,
            content: AnyView(content())
        )
    }

    static func destination<Dest: View>(
        subtitle: String? = nil,
        image: String? = nil,
        systemImage: String? = nil,
        imageAlignment: VerticalAlignment? = nil,
        showChevron: Bool? = true,
        style: CardStyle = .default,
        @ViewBuilder destination: () -> Dest,
        @ViewBuilder content: () -> some View = { EmptyView() } // default closure
    ) -> CardOptions {
        .init(
            subtitle: subtitle,
            image: image,
            systemImage: systemImage,
            imageAlignment: imageAlignment,
            intent: .destination(AnyView(destination())),
            showChevron: showChevron,
            style: style,
            content: AnyView(content())
        )
    }
}

enum CardIntent {
    case action(() -> Void)
    case destination(AnyView)
    
    static func destination<Content: View>(
        @ViewBuilder _ content: () -> Content
    ) -> CardIntent {
        .destination(AnyView(content()))
    }
}

enum CardStyle {
    case `default`
    case accent
    case secondary
    case error

    var background: Color {
        switch self {
        case .default:   return Color.accentColor.opacity(0.07)
        case .accent:    return Color.accentColor.opacity(0.15)
        case .secondary: return Color.gray.opacity(0.10)
        case .error:     return Color.red.opacity(0.12)
        }
    }

    var foreground: Color {
        switch self {
        case .default:   return Color.primary
        case .accent:    return Color.accentColor
        case .secondary: return Color.primary
        case .error:     return Color.red
        }
    }

    var accent: Color {
        switch self {
        case .default:   return Color.accentColor
        case .accent:    return Color.accentColor
        case .secondary: return Color.gray
        case .error:     return Color.red
        }
    }

    var chevron: Color {
        switch self {
        case .default:   return Color.secondary
        case .accent:    return Color.secondary
        case .secondary: return Color.gray
        case .error:     return Color.red.opacity(0.8)
        }
    }
}

