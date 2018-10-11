//
//  UITableViewControllerExtensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/27/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

extension UITableViewController {
    
    func updateWhenActive() {
        if UIApplication.shared.applicationState == .active {
            self.tableView.reloadData()
        }
    }
    
    func styleNavigationBar() {
        let font = UIFont(name:"Thonburi", size:20.0)
        var titleAttributes: [NSAttributedString.Key : Any]
        if let defaultTitleAttributes = UINavigationBar.appearance().titleTextAttributes {
            titleAttributes = defaultTitleAttributes
        } else {
            titleAttributes = [NSAttributedString.Key : Any]()
        }
        titleAttributes[NSAttributedString.Key.font] = font
        self.navigationController?.navigationBar.titleTextAttributes = titleAttributes
    }

    func styleUIBarButton(_ button:UIBarButtonItem) {
        let font = UIFont(name:"Thonburi", size:16.0)
        var titleAttributes: [NSAttributedString.Key: Any]
        if let defaultTitleAttributes = UINavigationBar.appearance().titleTextAttributes {
            titleAttributes = defaultTitleAttributes
        } else {
            titleAttributes = [NSAttributedString.Key: Any]()
        }
        titleAttributes[NSAttributedString.Key.font] = font
        button.setTitleTextAttributes(titleAttributes, for:UIControl.State())
    }

}

extension UIViewController {

    func presentAlertIngoringForcedDisconnect(title: String? = nil, error: Swift.Error) {
        guard let peripheralError = error as? PeripheralError else {
            present(UIAlertController.alert(title: "Connection error", error: error) { [weak self] _ in
                _ = self?.navigationController?.popToRootViewController(animated: true)
            }, animated: true)
            return
        }
        guard peripheralError != .forcedDisconnect else {
            return
        }
        present(UIAlertController.alert(title: "Connection error", error: error) { [weak self] _ in
            _ = self?.navigationController?.popToRootViewController(animated: true)
        }, animated: true)
    }

}
