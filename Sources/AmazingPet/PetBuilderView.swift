import AmazingPetCore
import SwiftUI

final class PetBuilderModel: ObservableObject {
    @Published var name: String
    @Published var look: PetLook {
        didSet { lookDidChange() }
    }
    @Published private(set) var sprites: PetSprites
    @Published private(set) var speciesPreviews: [Species: Sprite] = [:]
    @Published private(set) var coatPreviews: [(coat: Coat, sprite: Sprite)] = []

    private let onLookChange: (PetLook) -> Void
    private let onDone: () -> Void

    init(profile: PetProfile, onLookChange: @escaping (PetLook) -> Void = { _ in }, onDone: @escaping () -> Void = {}) {
        name = profile.name
        look = profile.look
        sprites = PetSprites(look: profile.look)
        self.onLookChange = onLookChange
        self.onDone = onDone
        refreshPreviews()
    }

    var profile: PetProfile {
        PetProfile(name: PetProfile.cleanName(name, fallback: L10n.defaultName), look: look)
    }

    func limitName() {
        if name.count > PetProfile.maxNameLength { name = String(name.prefix(PetProfile.maxNameLength)) }
    }

    func randomize() { look = .random() }
    func finish() { onDone() }

    private func lookDidChange() {
        sprites = PetSprites(look: look)
        refreshPreviews()
        onLookChange(look)
    }

    private func refreshPreviews() {
        let eyes = look.eyes
        speciesPreviews = Dictionary(uniqueKeysWithValues: Species.allCases.map {
            ($0, PetSprites(look: PetLook(species: $0, eyes: eyes)).walk[0])
        })
        coatPreviews = look.species.coats.map {
            ($0, PetSprites(look: PetLook(species: look.species, coat: $0, eyes: eyes)).walk[0])
        }
    }
}

struct PetBuilderView: View {
    static let size = CGSize(width: 540, height: 760)

    @ObservedObject var model: PetBuilderModel
    var isSnapshot = false

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                PixelLabel(text: L10n.builderTitle, size: 16, color: PixelTheme.highlight, scale: 2)
                PixelLabel(text: L10n.builderSubtitle, size: 10, color: PixelTheme.muted, scale: 1.5)
            }
            stage
            section(L10n.nameLabel) { nameField }
            section(L10n.speciesLabel, caption: L10n.title(model.look.species)) { speciesPicker }
            section(L10n.coatLabel, caption: L10n.title(model.look.coat)) { coatPicker }
            section(L10n.eyesLabel, caption: L10n.title(model.look.eyes)) { eyePicker }
            HStack(spacing: 16) {
                Button(action: model.randomize) { PixelLabel(text: L10n.randomButton, size: 11) }
                    .buttonStyle(PixelButtonStyle())
                Button(action: model.finish) { PixelLabel(text: L10n.doneButton, size: 11, color: PixelTheme.border) }
                    .buttonStyle(PixelButtonStyle(fill: PixelTheme.accent))
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(.top, 36)
        .padding(.horizontal, 24)
        .frame(width: Self.size.width, height: Self.size.height)
        .background(PixelBackground())
    }

    private var stage: some View {
        TimelineView(.periodic(from: .now, by: 0.22)) { context in
            let frame = isSnapshot ? 0 : Int(context.date.timeIntervalSinceReferenceDate / 0.22) % 2
            VStack(spacing: 0) {
                HStack(alignment: .bottom, spacing: PixelTheme.unit * 4) {
                    PixelImage(image: model.sprites.walk[frame].right, scale: 8)
                    PixelImage(image: Sprites.yarn[frame].right, scale: 8)
                }
                Rectangle().fill(Color(PixelTheme.ground)).frame(height: PixelTheme.unit * 2)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .pixelPanel()
        }
    }

    @ViewBuilder
    private var nameField: some View {
        if isSnapshot {
            PixelLabel(text: model.profile.name, size: 14)
                .frame(width: 220)
                .padding(.vertical, 6)
                .pixelPanel(shadow: false)
        } else {
            editableName
        }
    }

    private var editableName: some View {
        TextField("", text: $model.name, prompt: Text(L10n.defaultName))
            .textFieldStyle(.plain)
            .font(.custom(PixelTheme.fontName, size: 16))
            .foregroundStyle(Color(PixelTheme.text))
            .multilineTextAlignment(.center)
            .frame(width: 220)
            .padding(.vertical, 6)
            .pixelPanel(shadow: false)
            .onChange(of: model.name) { model.limitName() }
    }

    private var speciesPicker: some View {
        HStack(spacing: 6) {
            ForEach(Species.allCases, id: \.self) { species in
                swatch(selected: model.look.species == species) { model.look.species = species } content: {
                    if let preview = model.speciesPreviews[species] { PixelImage(image: preview.right, scale: 2.5) }
                }
            }
        }
    }

    private var coatPicker: some View {
        HStack(spacing: 10) {
            ForEach(model.coatPreviews, id: \.coat) { preview in
                swatch(selected: model.look.coat == preview.coat) { model.look.coat = preview.coat } content: {
                    PixelImage(image: preview.sprite.right, scale: 3)
                }
            }
        }
    }

    private var eyePicker: some View {
        HStack(spacing: 10) {
            ForEach(EyeColor.allCases, id: \.self) { eyes in
                swatch(selected: model.look.eyes == eyes) { model.look.eyes = eyes } content: {
                    Rectangle().fill(Color(eyes.swatch)).frame(width: 24, height: 24)
                }
            }
        }
    }

    private func swatch(selected: Bool, action: @escaping () -> Void, @ViewBuilder content: () -> some View) -> some View {
        Button(action: action) {
            content()
                .padding(5)
                .pixelPanel(border: selected ? PixelTheme.highlight : PixelTheme.border, shadow: !selected)
                .offset(y: selected ? -PixelTheme.unit : 0)
        }
        .buttonStyle(.plain)
    }

    private func section(_ title: String, caption: String? = nil, @ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                PixelLabel(text: title.uppercased(), size: 10, color: PixelTheme.muted)
                if let caption { PixelLabel(text: caption, size: 10, color: PixelTheme.text) }
            }
            content()
        }
    }
}
