import UIKit
final class EmojiCollectionViewController: UICollectionViewController {

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 44, height: 44)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        super.init(collectionViewLayout: layout)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.searchController = nil
        navigationItem.hidesSearchBarWhenScrolling = true
        removeEmbeddedSearchBars()
        // Register the EmojiCell class for reuse
        collectionView.register(EmojiCell.self, forCellWithReuseIdentifier: "EmojiCell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ensure no stray search bars are present when the view appears
        removeEmbeddedSearchBars()
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Placeholder count to ensure the controller compiles and runs
        return 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath)
        return cell
    }

    private func removeEmbeddedSearchBars() {
        // Remove any UISearchBar instances that might have been added as subviews (e.g., in headers)
        func removeSearchBars(in view: UIView) {
            for subview in view.subviews {
                if subview is UISearchBar {
                    subview.removeFromSuperview()
                } else {
                    removeSearchBars(in: subview)
                }
            }
        }
        removeSearchBars(in: self.view)
    }
}

