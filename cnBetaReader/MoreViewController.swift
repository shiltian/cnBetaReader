//
//  MoreViewController.swift
//  cnBetaReader
//
//  Created by Shilei Tian on 03/07/2017.
//  Copyright © 2017 TSL. All rights reserved.
//

import UIKit

class MoreViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                
            } else if indexPath.row == 1 {
                let url = URL(string: "mailto:tianshilei1992@gmail.com")
                UIApplication.shared.open(url!, options: [:], completionHandler: nil)
            }
        } else if indexPath.section == 2 {
            
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
