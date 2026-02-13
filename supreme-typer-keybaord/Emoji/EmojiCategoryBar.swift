//
//  EmojiSearchbar.swift
//  s-type
//
//  Created by Afzal on 2/9/26.
//

import UIKit

protocol EmojiCategoryBarDelegate: AnyObject {
    func didSelectCategory(_ category: String)
}

private class CategoryScrollView: UIScrollView {
    override func touchesShouldCancel(in view: UIView) -> Bool {
        if view is UIButton {
            return true
        }
        return super.touchesShouldCancel(in: view)
    }
}

class EmojiCategoryBar: UIView {

    weak var delegate: EmojiCategoryBarDelegate?

    private var categories: [String] = []
    private var buttons: [UIButton] = []

    private let scrollView: UIScrollView = {
        let sv = CategoryScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.delaysContentTouches = false
        sv.canCancelContentTouches = true
        return sv
    }()

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8
        sv.distribution = .fillProportionally
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    init(categories: [String]) {
        super.init(frame: .zero)
        self.categories = categories
        setupViews()
        setupButtons()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(scrollView)
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -8),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }

    private func setupButtons() {
        for category in categories {
            var config = UIButton.Configuration.plain()
            if category == "Recents" {
                config.title = "🕒"
            } else {
                config.title = category.prefix(3).uppercased()
            }
            config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            config.baseForegroundColor = .label
            
            let button = UIButton(configuration: config)
            // Use a custom title container properties if needed, or stick to font on label
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            
            button.layer.cornerRadius = 12
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.systemGray4.cgColor
            button.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)
            
            buttons.append(button)
            stackView.addArrangedSubview(button)
        }
        highlightButton(at: 0)
    }

    @objc private func categoryTapped(_ sender: UIButton) {
        guard let index = buttons.firstIndex(of: sender) else { return }
        highlightButton(at: index)
        delegate?.didSelectCategory(categories[index])
    }

    private func highlightButton(at index: Int) {
        for (i, button) in buttons.enumerated() {
            var config = button.configuration ?? .plain()
            if i == index {
                config.baseBackgroundColor = .systemBlue
                config.baseForegroundColor = .white
                button.backgroundColor = .systemBlue // Fallback for layer visibility if needed
            } else {
                config.baseBackgroundColor = .clear
                config.baseForegroundColor = .label
                button.backgroundColor = .clear
            }
            button.configuration = config
        }
    }
}
