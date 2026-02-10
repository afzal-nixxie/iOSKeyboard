import UIKit

class KeyboardViewController: UIInputViewController {

    // MARK: - State
    private var isNumbersLayout = false
    private var isSymbolsLayout = false
    private var isEmojiLayout = false
    private var isShiftEnabled = false
    private var isCapsLockEnabled = false
    private var verticalStack: UIStackView?
    private var bottomRowButtons: [UIButton] = []

    private var lastShiftTapTime: Date?
    private var deleteTimer: Timer?

    // Emoji
    private var emojiCollectionView: UICollectionView!
    private var filteredEmojis: [Emoji] = []

    private var categoryBarView: EmojiCategoryBar!

    override func viewDidLoad() {
        super.viewDidLoad()
        filteredEmojis = EmojiManager.shared.emojis
        setupKeyboard()
    }

    // MARK: - Build Keyboard
    private func setupKeyboard() {
        view.backgroundColor = .systemBackground
        verticalStack?.removeFromSuperview()
        bottomRowButtons.removeAll()

        // Vertical stack
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        verticalStack = stack

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6)
        ])

        if isEmojiLayout {
            setupEmojiLayout(stack)
        } else {
            setupLettersNumbersSymbols(stack)
        }
    }

    // MARK: - Letters / Numbers / Symbols Layout
    private func setupLettersNumbersSymbols(_ stack: UIStackView) {
        let lettersRows = [
            ["Q","W","E","R","T","Y","U","I","O","P"],
            ["A","S","D","F","G","H","J","K","L"],
            ["Shift","Z","X","C","V","B","N","M","Delete"]
        ]

        let numbersRows = [
            ["1","2","3","4","5","6","7","8","9","0"],
            ["-","/",":",";","(",")","$","&","@"],
            ["#+=",".",",","?","!","Delete"]
        ]

        let symbolsRows = [
            ["[","]","{","}","#","%","^","*","+","="],
            ["_","\\","|","~","<",">","€","£","¥","•"],
            ["123",".",",","?","!","Delete"]
        ]

        var rows: [[String]] = []

        if isSymbolsLayout {
            rows = symbolsRows
        } else if isNumbersLayout {
            rows = numbersRows
        } else {
            rows = lettersRows
        }

        // Add main rows
        for rowKeys in rows {
            let horizontalStack = UIStackView()
            horizontalStack.axis = .horizontal
            horizontalStack.spacing = 6
            horizontalStack.distribution = .fillEqually

            for key in rowKeys {
                let button = createKeyButton(for: key)
                horizontalStack.addArrangedSubview(button)
            }

            stack.addArrangedSubview(horizontalStack)
        }

        // Bottom row (fixed)
        let bottomRowKeys = ["?123", "Emoji", ".", "Space", ",", "Return"]
        let bottomStack = UIStackView()
        bottomStack.axis = .horizontal
        bottomStack.spacing = 6
        bottomStack.distribution = .fillEqually

        for key in bottomRowKeys {
            let button = createKeyButton(for: key)
            bottomStack.addArrangedSubview(button)
            bottomRowButtons.append(button)
        }
        stack.addArrangedSubview(bottomStack)

        updateBottomRowSpecialKeys()
    }

    // MARK: - Emoji Layout
    private func setupEmojiLayout(_ stack: UIStackView) {
        // Search Bar
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search Emoji"
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(searchBar)
        searchBar.heightAnchor.constraint(equalToConstant: 36).isActive = true

        // Category bar
        categoryBarView = EmojiCategoryBar(categories: EmojiManager.shared.categories)
        categoryBarView.delegate = self
        stack.addArrangedSubview(categoryBarView)
        categoryBarView.heightAnchor.constraint(equalToConstant: 36).isActive = true

        // Collection view
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 6
        layout.minimumInteritemSpacing = 6

        emojiCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        emojiCollectionView.register(EmojiCell.self, forCellWithReuseIdentifier: "EmojiCell")
        emojiCollectionView.dataSource = self
        emojiCollectionView.delegate = self
        emojiCollectionView.backgroundColor = .systemBackground
        emojiCollectionView.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(emojiCollectionView)
        emojiCollectionView.heightAnchor.constraint(equalToConstant: 200).isActive = true

        // Bottom row
        let bottomRow = UIStackView()
        bottomRow.axis = .horizontal
        bottomRow.spacing = 6
        bottomRow.distribution = .fill

        let abcButton = createKeyButton(for: "ABC")
        let spaceButton = createKeyButton(for: "Space")
        let deleteButton = createKeyButton(for: "Delete")

        bottomRow.addArrangedSubview(abcButton)
        bottomRow.addArrangedSubview(spaceButton)
        bottomRow.addArrangedSubview(deleteButton)
        abcButton.widthAnchor.constraint(equalTo: deleteButton.widthAnchor).isActive = true
        stack.addArrangedSubview(bottomRow)
    }

    // MARK: - Create Key Button
    private func createKeyButton(for key: String) -> UIButton {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 18)
        button.layer.cornerRadius = 6
        button.backgroundColor = .secondarySystemBackground
        button.setTitleColor(.label, for: .normal)
        button.tintColor = .label

        if key == "Shift" {
            let iconName = isCapsLockEnabled ? "capslock.fill" : "arrow.up"
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
            button.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
        } else {
            button.setTitle(applyShift(to: key), for: .normal)
        }

        // Shift / Caps Lock visuals
        if key == "Shift" {
            if isCapsLockEnabled {
                button.backgroundColor = .systemBlue
                button.tintColor = .white
            } else if isShiftEnabled {
                button.backgroundColor = .lightGray
                button.tintColor = .black
            }
        }

        if key == "?123" || key == "Return" {
            button.widthAnchor.constraint(equalToConstant: 50).isActive = true
        }

        if key == "Delete" {
            button.addTarget(self, action: #selector(deletePressed), for: .touchDown)
            button.addTarget(self, action: #selector(deleteReleased), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        } else {
            button.addTarget(self, action: #selector(keyPressed(_:)), for: .touchUpInside)
        }

        return button
    }

    // MARK: - Update Bottom Row
    private func updateBottomRowSpecialKeys() {
        if isEmojiLayout { return }
        if let keyButton = bottomRowButtons.first(where: { $0.currentTitle == "?123" || $0.currentTitle == "ABC" }) {
            keyButton.setTitle(isNumbersLayout ? "ABC" : "?123", for: .normal)
        }
    }

    // MARK: - Key Press
    @objc private func keyPressed(_ sender: UIButton) {
        guard let text = sender.title(for: .normal) else { return }

        switch text {
        case "Shift":
            handleShiftTap()
        case "?123", "ABC":
            if isEmojiLayout {
                isEmojiLayout = false
                isNumbersLayout = false
            } else {
                isNumbersLayout.toggle()
            }
            isSymbolsLayout = false // Always reset symbols when switching to/from numbers/letters
            isShiftEnabled = false
            isCapsLockEnabled = false
            setupKeyboard()
        case "#+=":
            isSymbolsLayout = true
            isNumbersLayout = false
            isShiftEnabled = false
            isCapsLockEnabled = false
            isEmojiLayout = false
            setupKeyboard()
        case "Space":
            textDocumentProxy.insertText(" ")
        case ".":
            textDocumentProxy.insertText(".")
        case ",":
            textDocumentProxy.insertText(",")
        case "Return":
            textDocumentProxy.insertText("\n")
        case "Emoji":
            isEmojiLayout = true
            isNumbersLayout = false
            isSymbolsLayout = false
            isShiftEnabled = false
            isCapsLockEnabled = false
            setupKeyboard()
        default:
            if isEmojiLayout {
                textDocumentProxy.insertText(text)
            } else {
                textDocumentProxy.insertText(applyShift(to: text))
                if isShiftEnabled && !isCapsLockEnabled && !isNumbersLayout && !isSymbolsLayout {
                    isShiftEnabled = false
                    setupKeyboard()
                }
            }
        }

        updateBottomRowSpecialKeys()
    }

    // MARK: - Shift / Caps Lock Logic
    private func handleShiftTap() {
        let now = Date()
        if let lastTap = lastShiftTapTime, now.timeIntervalSince(lastTap) < 0.5 {
            isCapsLockEnabled.toggle()
            isShiftEnabled = false
        } else {
            if isCapsLockEnabled {
                isCapsLockEnabled = false
                isShiftEnabled = false
            } else {
                isShiftEnabled.toggle()
            }
        }
        lastShiftTapTime = now
        setupKeyboard()
    }

    private func applyShift(to key: String) -> String {
        guard !isNumbersLayout && !isSymbolsLayout && !isEmojiLayout else { return key }
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        if letters.contains(key.uppercased()) {
            if isCapsLockEnabled || isShiftEnabled {
                return key.uppercased()
            } else {
                return key.lowercased()
            }
        }
        return key
    }

    // MARK: - Delete with Long Press
    @objc private func deletePressed() {
        textDocumentProxy.deleteBackward()
        deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.textDocumentProxy.deleteBackward()
        }
    }

    @objc private func deleteReleased() {
        deleteTimer?.invalidate()
        deleteTimer = nil
    }
}

// MARK: - UICollectionView
extension KeyboardViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredEmojis.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath) as! EmojiCell
        let emoji = filteredEmojis[indexPath.item]
        cell.label.text = emoji.text ?? emoji.name
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let emoji = filteredEmojis[indexPath.item]
        textDocumentProxy.insertText(emoji.text ?? emoji.name)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 36, height: 36)
    }
}

// MARK: - EmojiCategoryBarDelegate
extension KeyboardViewController: EmojiCategoryBarDelegate {
    func didSelectCategory(_ category: String) {
        filteredEmojis = EmojiManager.shared.emojis(for: category)
        emojiCollectionView.reloadData()
    }
}

// MARK: - UISearchBarDelegate
extension KeyboardViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredEmojis = EmojiManager.shared.emojis
        } else {
            filteredEmojis = EmojiManager.shared.search(searchText)
        }
        emojiCollectionView.reloadData()
    }
}
