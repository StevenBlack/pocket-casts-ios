import SwiftUI
import PocketCastsServer

struct PlusPurchaseModal: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var coordinator: PlusPurchaseModel

    @State var selectedOption: Constants.IapProducts
    @State var freeTrialDuration: String?

    var pricingInfo: PlusPurchaseModel.PlusPricingInfo {
        coordinator.pricingInfo
    }

    init(coordinator: PlusPurchaseModel) {
        self.coordinator = coordinator
        let firstProduct = coordinator.pricingInfo.products.first

        _selectedOption = State(initialValue: firstProduct?.identifier ?? .yearly)
        _freeTrialDuration = State(initialValue: firstProduct?.freeTrialDuration)
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            ModalTopPill(fillColor: .imageFilter01)

            Label(L10n.plusPurchasePromoTitle, for: .title)
                .foregroundColor(Color.textColor)
                .padding(.top, 32)
                .padding(.bottom, pricingInfo.hasFreeTrial ? 15 : 0)

            if let freeTrialDuration {
                PlusFreeTrialLabel(freeTrialDuration)
            }

            VStack(spacing: 16) {
                ForEach(pricingInfo.products) { product in
                    // Hide any unselected items if we're in the failed state, this saves space for the error message
                    if coordinator.state != .failed || selectedOption == product.identifier {
                        Button(product.price) {
                            selectedOption = product.identifier
                            freeTrialDuration = product.freeTrialDuration
                        }
                        .disabled(coordinator.state == .failed)
                        .buttonStyle(PlusGradientStrokeButton(isSelectable: true, isSelected: selectedOption == product.identifier))
                    }
                }

                // Show how long the free trial is if there is one
                if let freeTrialDuration {
                    Label(L10n.pricingTermsAfterTrialLong(freeTrialDuration), for: .freeTrialTerms)
                        .foregroundColor(Color.textColor)
                        .lineSpacing(1.2)
                }

                // Show the error message if we're in the failed state
                if coordinator.state == .failed {
                    PlusDivider()

                    Label(L10n.plusPurchaseFailed, for: .error).foregroundColor(.error)
                }

                PlusDivider()

                let isLoading = (coordinator.state == .purchasing)
                Button(subscribeButton) {
                    guard !isLoading else { return }
                    coordinator.purchase(product: selectedOption)
                }.buttonStyle(PlusGradientFilledButtonStyle(isLoading: isLoading)).disabled(isLoading)

                TermsView(text: Config.termsHTML)
            }.padding(.top, 23)
        }
        .frame(maxWidth: Config.maxWidth)
        .padding([.leading, .trailing])
        .padding(.bottom, 60)
        .background(Color.backgroundColor.ignoresSafeArea())
    }

    private var subscribeButton: String {
        if coordinator.state == .failed {
            return L10n.tryAgain
        }

        if pricingInfo.hasFreeTrial {
            return L10n.freeTrialStartAndSubscribeButton
        }

        return L10n.subscribe
    }

    enum Config {
        static let backgroundColorHex = "#282829"
        static let maxWidth: CGFloat = 600
        static let termsHTML = L10n.purchaseTerms("<a href=\"\(ServerConstants.Urls.privacyPolicy)\">", "</a>", "<a href=\"\(ServerConstants.Urls.termsOfUse)\">", "</a>")
    }
}

// MARK: - Config
private extension Color {
    static let backgroundColor = Color(hex: PlusPurchaseModal.Config.backgroundColorHex)
    static let textColor = Color(hex: "#FFFFFF")
    static let uiTextColor = UIColor(hex: "#FFFFFF")
    static let error = AppTheme.color(for: .support05)
}

// MARK: - Views
private struct PlusDivider: View {
    var body: some View {
        Divider().background(Color(hex: "#E4E4E4")).opacity(0.24)
    }
}

private struct TermsView: View {
    @State var labelSize: CGSize = .zero
    let text: String

    var body: some View {
        GeometryReader { geometry in
            HTMLTextView(text: text,
                         font: .font(ofSize: 14, weight: .regular, scalingWith: .footnote),
                         textColor: Color.uiTextColor,
                         width: geometry.size.width,
                         textViewSize: $labelSize)
        }.frame(height: labelSize.height)
    }
}

private struct Label: View {
    enum LabelStyle {
        case title
        case freeTrialTerms
        case error
    }

    let text: String
    let labelStyle: LabelStyle

    init(_ text: String, for style: LabelStyle) {
        self.text = text
        self.labelStyle = style
    }

    var body: some View {
        Text(text)
            .fixedSize(horizontal: false, vertical: true)
            .modifier(LabelFont(labelStyle: labelStyle))
            .multilineTextAlignment(.center)
    }

    private struct LabelFont: ViewModifier {
        let labelStyle: LabelStyle

        func body(content: Content) -> some View {
            switch labelStyle {
            case .title:
                return content.font(size: 22, style: .title2, weight: .bold, maxSizeCategory: .extraExtraExtraLarge)
            case .freeTrialTerms:
                return content.font(size: 13, style: .caption, maxSizeCategory: .extraExtraLarge)
            case .error:
                return content.font(style: .subheadline, maxSizeCategory: .extraExtraExtraLarge)
            }
        }
    }
}

// MARK: - Preview
struct PlusPurchaseOptions_Previews: PreviewProvider {
    static var previews: some View {
        PlusPurchaseModal(coordinator: PlusPurchaseModel())
            .setupDefaultEnvironment()
    }
}
