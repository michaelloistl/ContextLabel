//
//  TableViewCell.swift
//  ContextLabel
//
//  Created by Michael Loistl on 27/03/2017.
//  Copyright © 2017 Aplo. All rights reserved.
//

import Foundation
import UIKit

protocol TableViewCellDelegate: class {
    func tableViewCell(_ sender: TableViewCell, didTouchWith touchResult: TouchResult)
}

class TableViewCell: UITableViewCell {
    
    weak var delegate: TableViewCellDelegate?
    
    lazy var contextLabel: ContextLabel = {
        var frame = CGRect(x: 16, y: 0, width: self.contentView.bounds.width - 32, height: self.contentView.bounds.height)
        
        // Initialize ContextLabel
        let _label = ContextLabel(frame: frame, didTouch: { (touchResult) in
            self.delegate?.tableViewCell(self, didTouchWith: touchResult)
        })
        
        // Custom Text Color (optional)
        _label.foregroundColor = { (linkResult) in
            switch linkResult.detectionType {
            case .userHandle:
                return .red
            case .hashtag:
                return .blue
            case .url:
                return .gray
            case .textLink:
                return .black
            default:
                return .black
            }
        }

        // Custoim Underline Style (optional)
        _label.underlineStyle = { (linkResult) in
            switch linkResult.detectionType {
            case .userHandle, .hashtag:
                return .styleDouble
            case .url:
                return .styleSingle
            case .textLink:
                return .styleSingle
            default:
                return .styleNone
            }
        }
        
        // Any default UILabel properties
        _label.font = .systemFont(ofSize: 16)
        
        return _label
    }()
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(contextLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Super
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch contextLabel.touchState {
        case .began:
            break
        default:
            super.touchesBegan(touches, with: event)
        }
    }
    
    // MARK: - Methods
    
    func config(with text: String, textLinks: [TextLink]?) {
        contextLabel.text = text
        contextLabel.textLinks = textLinks
    }
    
    
}
