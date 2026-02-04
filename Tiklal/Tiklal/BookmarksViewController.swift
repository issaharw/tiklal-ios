//
//  BookmarksViewController.swift
//
//  Tiklal
//
//  Created by Issahar Weiss on 2024.
//

import UIKit

class BookmarksViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // Current position from main view
    var currentMajor: Int = 0
    var currentMinor: Int = 0
    var currentMajorTitle: String = ""
    var currentMinorTitle: String = ""
    var showLastPositionUI: Bool = true
    
    // Callback for navigation
    var onNavigate: ((Int, Int) -> Void)?
    
    private var bookmarks: [Bookmark] = []
    private var lastPosition: Bookmark?
    
    private let tableView = UITableView()
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let backButton = UIButton(type: .system)
    private let addButton = UIButton(type: .system)
    private let emptyLabel = UILabel()
    private let lastPositionView = UIView()
    private let lastPositionTitleLabel = UILabel()
    private let lastPositionLabel = UILabel()
    private let continueButton = UIButton(type: .system)
    
    private let primaryColor = UIColor(red: 0x42/255, green: 0x6F/255, blue: 0x8C/255, alpha: 1)
    private let secondaryColor = UIColor(red: 0x5C/255, green: 0x84/255, blue: 0xA2/255, alpha: 1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupHeader()
        setupAddButton()
        setupTableView()
        setupEmptyLabel()
        setupLastPositionView()
        
        loadData()
        updateUI()
    }
    
    private func setupHeader() {
        headerView.backgroundColor = primaryColor
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        
        backButton.setTitle("←", for: .normal)
        backButton.setTitleColor(.white, for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(backButton)
        
        titleLabel.text = "סימניות"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 100),
            
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            backButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -12),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupAddButton() {
        addButton.setTitle("+ הוסף סימניה למיקום הנוכחי", for: .normal)
        addButton.backgroundColor = primaryColor
        addButton.setTitleColor(.white, for: .normal)
        addButton.layer.cornerRadius = 8
        addButton.addTarget(self, action: #selector(addBookmarkTapped), for: .touchUpInside)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            addButton.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 12),
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(BookmarkCell.self, forCellReuseIdentifier: "BookmarkCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .singleLine
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: addButton.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -150)
        ])
    }
    
    private func setupEmptyLabel() {
        emptyLabel.text = "אין סימניות שמורות"
        emptyLabel.textColor = .gray
        emptyLabel.textAlignment = .center
        emptyLabel.font = UIFont.systemFont(ofSize: 18)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])
    }
    
    private func setupLastPositionView() {
        lastPositionView.backgroundColor = secondaryColor
        lastPositionView.translatesAutoresizingMaskIntoConstraints = false
        lastPositionView.isHidden = true
        view.addSubview(lastPositionView)
        
        lastPositionTitleLabel.text = "המשך קריאה מהמיקום האחרון:"
        lastPositionTitleLabel.textColor = .white
        lastPositionTitleLabel.font = UIFont.systemFont(ofSize: 14)
        lastPositionTitleLabel.textAlignment = .right
        lastPositionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        lastPositionView.addSubview(lastPositionTitleLabel)
        
        lastPositionLabel.textColor = .white
        lastPositionLabel.font = UIFont.systemFont(ofSize: 16)
        lastPositionLabel.textAlignment = .right
        lastPositionLabel.numberOfLines = 2
        lastPositionLabel.translatesAutoresizingMaskIntoConstraints = false
        lastPositionView.addSubview(lastPositionLabel)
        
        continueButton.setTitle("עבור למיקום", for: .normal)
        continueButton.backgroundColor = .white
        continueButton.setTitleColor(primaryColor, for: .normal)
        continueButton.layer.cornerRadius = 8
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        lastPositionView.addSubview(continueButton)
        
        NSLayoutConstraint.activate([
            lastPositionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            lastPositionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            lastPositionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            lastPositionView.heightAnchor.constraint(equalToConstant: 150),
            
            lastPositionTitleLabel.topAnchor.constraint(equalTo: lastPositionView.topAnchor, constant: 16),
            lastPositionTitleLabel.trailingAnchor.constraint(equalTo: lastPositionView.trailingAnchor, constant: -16),
            lastPositionTitleLabel.leadingAnchor.constraint(equalTo: lastPositionView.leadingAnchor, constant: 16),
            
            lastPositionLabel.topAnchor.constraint(equalTo: lastPositionTitleLabel.bottomAnchor, constant: 4),
            lastPositionLabel.trailingAnchor.constraint(equalTo: lastPositionView.trailingAnchor, constant: -16),
            lastPositionLabel.leadingAnchor.constraint(equalTo: lastPositionView.leadingAnchor, constant: 16),
            
            continueButton.topAnchor.constraint(equalTo: lastPositionLabel.bottomAnchor, constant: 12),
            continueButton.leadingAnchor.constraint(equalTo: lastPositionView.leadingAnchor, constant: 16),
            continueButton.trailingAnchor.constraint(equalTo: lastPositionView.trailingAnchor, constant: -16),
            continueButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func loadData() {
        // Load bookmarks
        if let json = UserDefaults.standard.string(forKey: "bookmarks"),
           let data = json.data(using: .utf8),
           let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            bookmarks = array.compactMap { Bookmark(from: $0) }
        }
        
        // Load last position
        if let json = UserDefaults.standard.string(forKey: "lastPosition"),
           let data = json.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            lastPosition = Bookmark(from: dict)
        }
    }
    
    private func updateUI() {
        tableView.reloadData()
        emptyLabel.isHidden = !bookmarks.isEmpty
        tableView.isHidden = bookmarks.isEmpty
        
        if showLastPositionUI, let pos = lastPosition {
            lastPositionView.isHidden = false
            lastPositionLabel.text = "\(pos.majorTitle)\n\(pos.minorTitle)"
        } else {
            lastPositionView.isHidden = true
        }
        
        // Update table view bottom constraint based on last position visibility
        tableView.constraints.forEach { constraint in
            if constraint.firstAttribute == .bottom {
                constraint.constant = lastPositionView.isHidden ? 0 : -150
            }
        }
    }
    
    @objc private func backTapped() {
        dismiss(animated: true)
    }
    
    @objc private func addBookmarkTapped() {
        // Check if bookmark already exists
        if bookmarks.contains(where: { $0.major == currentMajor && $0.minor == currentMinor }) {
            showToast(message: "סימניה זו כבר קיימת")
            return
        }
        
        let newBookmark = Bookmark(
            major: currentMajor,
            minor: currentMinor,
            majorTitle: currentMajorTitle,
            minorTitle: currentMinorTitle
        )
        bookmarks.insert(newBookmark, at: 0)
        saveBookmarks()
        updateUI()
        showToast(message: "הסימניה נוספה")
    }
    
    @objc private func continueTapped() {
        if let pos = lastPosition {
            dismiss(animated: true) {
                self.onNavigate?(pos.major, pos.minor)
            }
        }
    }
    
    private func saveBookmarks() {
        let array = bookmarks.map { $0.toDictionary() }
        if let data = try? JSONSerialization.data(withJSONObject: array),
           let json = String(data: data, encoding: .utf8) {
            UserDefaults.standard.set(json, forKey: "bookmarks")
        }
    }
    
    private func showToast(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookmarks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BookmarkCell", for: indexPath) as! BookmarkCell
        let bookmark = bookmarks[indexPath.row]
        cell.configure(majorTitle: bookmark.majorTitle, minorTitle: bookmark.minorTitle)
        cell.onDelete = { [weak self] in
            self?.deleteBookmark(at: indexPath.row)
        }
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let bookmark = bookmarks[indexPath.row]
        dismiss(animated: true) {
            self.onNavigate?(bookmark.major, bookmark.minor)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    private func deleteBookmark(at index: Int) {
        bookmarks.remove(at: index)
        saveBookmarks()
        updateUI()
    }
}

// MARK: - BookmarkCell

class BookmarkCell: UITableViewCell {
    
    var onDelete: (() -> Void)?
    
    private let majorLabel = UILabel()
    private let minorLabel = UILabel()
    private let deleteButton = UIButton(type: .system)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        majorLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        majorLabel.textAlignment = .right
        majorLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(majorLabel)
        
        minorLabel.font = UIFont.systemFont(ofSize: 14)
        minorLabel.textColor = .gray
        minorLabel.textAlignment = .right
        minorLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(minorLabel)
        
        deleteButton.setTitle("🗑", for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            deleteButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            deleteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 44),
            deleteButton.heightAnchor.constraint(equalToConstant: 44),
            
            majorLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            majorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            majorLabel.leadingAnchor.constraint(equalTo: deleteButton.trailingAnchor, constant: 8),
            
            minorLabel.topAnchor.constraint(equalTo: majorLabel.bottomAnchor, constant: 4),
            minorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            minorLabel.leadingAnchor.constraint(equalTo: deleteButton.trailingAnchor, constant: 8)
        ])
    }
    
    func configure(majorTitle: String, minorTitle: String) {
        majorLabel.text = majorTitle
        minorLabel.text = minorTitle
    }
    
    @objc private func deleteTapped() {
        onDelete?()
    }
}
