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
        view.backgroundColor = UIColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 1.0) // Darker yellow background
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
            ["€\\<","#","%","+","?","!","Delete"]
        ]

        let symbolsRows = [
            ["[", "]", "{", "}", "^", "*", "=", "°", "·", "±"],
            ["_", "\\", "|", "~", "<", ">", "÷", "£", "¥", "•"],
            ["?123", "×", "¶", "§", "©", "Delete"]
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
        for (index, rowKeys) in rows.enumerated() {
            let horizontalStack = UIStackView()
            horizontalStack.axis = .horizontal
            horizontalStack.spacing = 6
            horizontalStack.distribution = .fill

            var keys = rowKeys
            // Add spacers for the second row of letters (ASDF...) to indent it
            if !isNumbersLayout && !isSymbolsLayout && index == 1 {
                keys = ["Spacer"] + keys + ["Spacer"]
            }

            var referenceView: UIView?
            var referenceUnit: CGFloat = 1.0

            for key in keys {
                let view: UIView
                if key == "Spacer" {
                    let spacer = UIView()
                    // Spacers need intrinsic size placeholders or just constraints?
                    // Constraints are sufficient.
                    view = spacer
                } else {
                    let button = createKeyButton(for: key)
                    button.titleLabel?.adjustsFontSizeToFitWidth = true
                    button.titleLabel?.minimumScaleFactor = 0.5
                    view = button
                }
                horizontalStack.addArrangedSubview(view)
                
                let unit = getKeyWidthUnit(for: key)
                
                if let ref = referenceView {
                    // constrain width = reference * (unit/refUnit)
                    view.widthAnchor.constraint(equalTo: ref.widthAnchor, multiplier: unit / referenceUnit).isActive = true
                } else {
                    referenceView = view
                    referenceUnit = unit
                }
            }

            horizontalStack.heightAnchor.constraint(equalToConstant: 50).isActive = true
            stack.addArrangedSubview(horizontalStack)
        }

        // Bottom row (fixed)
        let bottomRowKeys = ["ModeSwitch", "Emoji", ".", "Space", ",", "Return"]
        let bottomStack = UIStackView()
        bottomStack.axis = .horizontal
        bottomStack.spacing = 6
        bottomStack.distribution = .fill

        var bottomRefView: UIView?
        var bottomRefUnit: CGFloat = 1.0

        for key in bottomRowKeys {
            let button = createKeyButton(for: key)
            // Adjusts font size for all keys to prevent cramping
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = 0.5
            
            bottomStack.addArrangedSubview(button)
            bottomRowButtons.append(button)
            
            let unit = getKeyWidthUnit(for: key)
            if let ref = bottomRefView {
                 button.widthAnchor.constraint(equalTo: ref.widthAnchor, multiplier: unit / bottomRefUnit).isActive = true
            } else {
                bottomRefView = button
                bottomRefUnit = unit
            }
        }
        bottomStack.heightAnchor.constraint(equalToConstant: 50).isActive = true
        stack.addArrangedSubview(bottomStack)


    }

    private func getKeyWidthUnit(for key: String) -> CGFloat {
        switch key {
        case "Shift", "Delete", "Return":
            return 1.5
        case "?123", "ABC", "€\\<", "ModeSwitch":
            return 1.25
        case "Space":
            return 4.0 // Leaving 6 units for other 5 keys (1.5+1+1+1+1.5 = 6) -> Total 10. 
                       // Wait: ?123(1.5), Emoji(1), .(1), Space(4), ,(1), Return(1.5) = 10.
        case "Spacer":
            return 0.5
        case "123": // In symbols layout? No, "?123" is key. "123" is symbol key.
             if isSymbolsLayout { return 1.5 } // "123" key updates to "ABC" usually?
             return 1.0
        default:
            return 1.0
        }
    }

    // MARK: - Emoji Layout
    private func setupEmojiLayout(_ stack: UIStackView) {
        // Initialize with first category (Recents)
        if let firstCategory = EmojiManager.shared.categories.first {
            filteredEmojis = EmojiManager.shared.emojis(for: firstCategory)
        }
        
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
        emojiCollectionView.backgroundColor = .clear
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
        
        // ABC and Delete are small (1.25 units), Space fills the wide center gap (7.5 units)
        deleteButton.widthAnchor.constraint(equalTo: abcButton.widthAnchor).isActive = true
        spaceButton.widthAnchor.constraint(equalTo: abcButton.widthAnchor, multiplier: 7.5 / 1.25).isActive = true
        
        bottomRow.heightAnchor.constraint(equalToConstant: 50).isActive = true
        stack.addArrangedSubview(bottomRow)
    }

    // MARK: - Create Key Button
    private func createKeyButton(for key: String) -> UIButton {
        let button = UIButton(type: .system)
        button.accessibilityIdentifier = key
        button.titleLabel?.font = .systemFont(ofSize: 18)
        button.layer.cornerRadius = 6
        button.backgroundColor = .secondarySystemBackground
        button.setTitleColor(.label, for: .normal)

        if key == "Shift" {
            let image = UIImage(systemName: "shift")
            button.setImage(image, for: .normal)
            button.tintColor = .label

            // Shift / Caps Lock visuals
            if isCapsLockEnabled {
                button.backgroundColor = .systemBlue
                button.tintColor = .white
            } else if isShiftEnabled {
                button.backgroundColor = .lightGray
                button.tintColor = .black
            }
        } else if key == "Emoji" {
            button.setTitle("😀", for: .normal)
        } else if key == "Delete" {
            let image = UIImage(systemName: "delete.left")
            button.setImage(image, for: .normal)
            button.tintColor = .label
        } else if key == "Return" {
            let image = UIImage(systemName: "return")
            button.setImage(image, for: .normal)
            button.tintColor = .label
        } else if key == "ModeSwitch" {
            let title = (isNumbersLayout || isSymbolsLayout) ? "ABC" : "?123"
            button.setTitle(title, for: .normal)
        } else {
            button.setTitle(applyShift(to: key), for: .normal)
        }

        if key == "ModeSwitch" || key == "?123" || key == "€\\<" || key == "ABC" {
            button.titleLabel?.font = .systemFont(ofSize: 14)
        }

        if key == "Delete" {
            button.addTarget(self, action: #selector(deletePressed), for: .touchDown)
            button.addTarget(self, action: #selector(deleteReleased), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        } else {
            button.addTarget(self, action: #selector(keyPressed(_:)), for: .touchUpInside)
        }

        return button
    }



    // MARK: - Key Press
    @objc private func keyPressed(_ sender: UIButton) {
        guard let text = sender.accessibilityIdentifier ?? sender.title(for: .normal) else { return }

        switch text {
        case "Shift":
            handleShiftTap()
        case "ModeSwitch", "ABC":
            // Bottom-left key: Always toggles between Letters and Numbers/Symbols
            // If in Symbols or Numbers -> Go to Letters
            // If in Letters -> Go to Numbers
            if isNumbersLayout || isSymbolsLayout || isEmojiLayout {
                isEmojiLayout = false
                isNumbersLayout = false
                isSymbolsLayout = false
            } else {
                isNumbersLayout = true
            }
            setupKeyboard()
            
        case "?123", "123", "€\\<":
            // Toggle between Numbers and Symbols
            // If in Numbers -> Go to Symbols
            // If in Symbols -> Go to Numbers
            if isSymbolsLayout {
                isSymbolsLayout = false
                isNumbersLayout = true
            } else {
                isSymbolsLayout = true
                isNumbersLayout = false
            }
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
        cell.label.text = emoji.text
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let emoji = filteredEmojis[indexPath.item]
        textDocumentProxy.insertText(emoji.text)
        EmojiManager.shared.addToRecents(emoji)
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
