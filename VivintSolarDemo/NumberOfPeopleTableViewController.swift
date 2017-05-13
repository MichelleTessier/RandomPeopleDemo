//
//  NumberOfPeopleTableViewController.swift
//  VivintSolarDemo
//
//  Created by Michelle Tessier on 5/12/17.
//  Copyright © 2017 Michelle Tessier. All rights reserved.
//

import UIKit

protocol NumberOfPeopleDelegate : class {
    func numberOfPeopleChanged()
}

class NumberOfPeopleTableViewController: UITableViewController {
    
    static let kNumberOfPeopleCellId = "kNumberOfPeopleCellId"
    static let kNumberOfPeopleKey = "kNumberOfPeopleKey"
    
    weak var numberOfPeopleDelegate : NumberOfPeopleDelegate?
    
    let numberOfPeopleChoices = [1, 10, 50, 80, 100, 150, 1000, 5000]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.allowsMultipleSelection = false

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
     
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return numberOfPeopleChoices.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NumberOfPeopleTableViewController.kNumberOfPeopleCellId, for: indexPath)

        let count = numberOfPeopleChoices[indexPath.row]
        
        cell.textLabel?.text = count.description
        if count == UserDefaults.standard.integer(forKey: NumberOfPeopleTableViewController.kNumberOfPeopleKey) {
            cell.accessoryType = .checkmark
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let numberOfPeople = numberOfPeopleChoices[indexPath.row]
        UserDefaults.standard.set(numberOfPeople, forKey: NumberOfPeopleTableViewController.kNumberOfPeopleKey)
        self.numberOfPeopleDelegate?.numberOfPeopleChanged()
        self.navigationController?.popViewController(animated: true)
        
    }

    

}
