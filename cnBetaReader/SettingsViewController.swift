//
//  SettingsViewController.swift
//  cnBetaReader
//
//  Created by Shilei Tian on 2018/6/10.
//  Copyright © 2018 TSL. All rights reserved.
//

import UIKit
import CoreData

class SettingsViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                // clean the core data
                do {
                    try cleanCache()
                } catch {
                    presentAlertView(message: error.localizedDescription, present: present)
                }
            }
        }
    }
    
    private func cleanCache() throws {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            // failed to get the shared app delegate
            throw HTTPFetcherError(message: "failed to get the shared app delegate", kind: .internalError)
        }
        
        let context = appDelegate.persistentContainer.viewContext
        
        // 1. clean the cache of articles' contents
        let articleContentFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ArticleContent")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: articleContentFetchRequest)
        try context.execute(deleteRequest)

        appDelegate.saveContext()
    }
    
}
