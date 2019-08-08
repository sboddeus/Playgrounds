//
//  AudioMenuController.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import UIKit

protocol AudioMenuDelegate: class {
    func enableBackgroundAudio(_ isEnabled: Bool)
    func enableSoundEffectsAudio(_ isEnabled: Bool)
}

class AudioMenuController: UITableViewController {
    
    static let cellIdentifier = "SwitchTableViewCell"
    
    enum CellIndex: Int {
        case backgroundAudio
        case soundEffectsAudio
    }
    
    // MARK: Properties
    
    weak var delegate: AudioMenuDelegate?
    var backgroundAudioEnabled = PersistentStore.isBackgroundAudioEnabled
    var soundEffectsAudioEnabled = PersistentStore.isSoundEffectsEnabled
    
    // MARK: View Controller Life-Cycle 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.isScrollEnabled = false
        tableView.allowsSelection = false
        tableView.separatorInset = .zero
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: AudioMenuController.cellIdentifier)
        
        tableView.tableFooterView = UIView()
    }
    
    override var preferredContentSize: CGSize {
        get {
            let rowHeight: CGFloat = 44
            let padding: CGFloat = 48
            var preferredSize = CGSize(width: 0, height: rowHeight * CGFloat(tableView.numberOfRows(inSection: 0)))
            for cell in tableView.visibleCells {
                guard let label = cell.textLabel, let accessoryView = cell.accessoryView else { continue }
                label.sizeToFit()
                let cellWidth = label.frame.width + accessoryView.frame.width + padding
                preferredSize.width = max(cellWidth, preferredSize.width)
            }
            return preferredSize
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let index = CellIndex(rawValue: indexPath.row) else {
            fatalError("Invalid index \(indexPath.row) in \(self)")
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: AudioMenuController.cellIdentifier, for: indexPath)        
        cell.textLabel?.font = UIFont(name: "SanFranciscoDisplay-Regular", size: 17)
        
        let switchControl = UISwitch()
        cell.accessoryView = switchControl
        
        switch index {
        case .backgroundAudio:
            cell.textLabel?.text = NSLocalizedString("Background music", comment: "Menu label")
            switchControl.isOn = backgroundAudioEnabled
            
            switchControl.addTarget(self, action: #selector(toggleBackgroundAudio(_:)), for: .valueChanged)
            
        case .soundEffectsAudio:
            cell.textLabel?.text = NSLocalizedString("Sound effects", comment: "Menu label")
            switchControl.isOn = soundEffectsAudioEnabled
            
            switchControl.addTarget(self, action: #selector(toggleSoundEffectsAudio), for: .valueChanged)
        }
        
        return cell
    }
    
    // MARK: Switch Actions
    
    @objc func toggleBackgroundAudio(_ control: UISwitch) {
        delegate?.enableBackgroundAudio(control.isOn)
    }
    
    @objc func toggleSoundEffectsAudio(_ control: UISwitch) {
        delegate?.enableSoundEffectsAudio(control.isOn)
    }
}
