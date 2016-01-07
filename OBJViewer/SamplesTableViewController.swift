//
//  SamplesTableViewController.swift
//  OBJViewer
//
//  Created by Todd Johnson on 1/6/16.
//  Copyright © 2016 Todd Johnson. All rights reserved.
//

import UIKit

class SamplesTableViewController: UITableViewController {

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let files = ["ducky", "trumpet", "skyscraper"]
        self.performSegueWithIdentifier("sceneSegue", sender: files[indexPath.row])
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let sceneVC = segue.destinationViewController as? SceneViewController {
            sceneVC.objFilename = sender as? String
        }
    }

}
