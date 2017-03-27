//
//  ViewController.swift
//  ContextLabel
//
//  Created by Michael Loistl on 17/03/2017.
//  Copyright © 2017 Aplo. All rights reserved.
//

import UIKit

class ViewController: UITableViewController, TableViewCellDelegate {

    let dataSource = [
    "Hashtag: #tag\n\nUser",
    "Mention: @user",
    "Text link: text link",
    "Detected link: www.google.com"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "ContextLabel Example"
        view.backgroundColor = .white
        
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "identifier")
    }
    
    // MARK: - Protocols
    
    // MARK: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "identifier", for: indexPath) as! TableViewCell
        cell.delegate = self
        
        // Optional Text Link
        
        var textLinks: [TextLink] = []
        if indexPath.row == 2 {
            let textLink = TextLink(text: "text link", range: NSRange(location: 11, length: 9)) {
                NSLog("Text Link Action ...")
            }
            textLinks = [textLink]
        }
        
        
        cell.config(with: dataSource[indexPath.row], textLinks: textLinks)
        return cell
    }
    
    // MARK: TableViewCellDelegate
    
    func tableViewCell(_ sender: TableViewCell, didTouchWith touchResult: TouchResult) {
        if touchResult.state == .ended {
            var alertController: UIAlertController?
            
            if let textLink = touchResult.linkResult?.textLink {
                alertController = UIAlertController(title: "Text Link", message: "\(textLink.text) - Range: \(NSStringFromRange(textLink.range!))", preferredStyle: .alert)
            } else if let linkResult = touchResult.linkResult {
                alertController = UIAlertController(title: "Link Result", message: "\(linkResult.text) - Range: \(NSStringFromRange(linkResult.range))", preferredStyle: .alert)
            }
            
            if let alertController = alertController {
                alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
                present(alertController, animated: true, completion: { 
                    
                })
            }
        }
    }
}

