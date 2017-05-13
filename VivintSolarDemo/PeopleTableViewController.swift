//
//  PeopleTableViewController.swift
//  VivintSolarDemo
//
//  Created by Michelle Tessier on 5/12/17.
//  Copyright © 2017 Michelle Tessier. All rights reserved.
//

import UIKit
import CoreData

class PeopleTableViewController: UITableViewController {
  
    
    var randomPeople : [Person] = []
    
    static let kPersonCellIdentifier = "kPersonCellIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fetchRequest = NSFetchRequest<Person>(entityName: "Person")
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let people = try? VivintSolarDemoDataModel.sharedModel.mainContext.fetch(fetchRequest)
        if let people = people, people.count > 0 {
            randomPeople = people
        } else {
            fetchRandomPeople()
        }
   
    }
    
    
    @IBAction func handleRefresh(_ sender: Any) {
        fetchRandomPeople()
        refreshControl?.endRefreshing()
    }
    
    func fetchRandomPeople() {
        
        var newRandomPeople : [Person] = []
        
        let context = VivintSolarDemoDataModel.sharedModel.mainContext
        
        var count = UserDefaults.standard.integer(forKey: NumberOfPeopleTableViewController.kNumberOfPeopleKey)
        
        if count <= 0 { count = 10 }
        
        PeopleWebService.getDataForRandomPeople(count: count) { webPeople, error in
            
            guard let webPeople = webPeople, error == nil else {
                self.presentFetchErrorAlertForError(error : error)
                return
            }
            
            for person in webPeople {
                PeopleCoreDataService.createPersonFromWebPerson(person, context: context) { person in
                    
                    guard let person = person else { return }
                    
                    newRandomPeople.append(person)
                    
                }
           
            }
            
            //Wrapping in a context.perform block ensures that it will be scheduled last after all of the above background blocks are run
            context.perform {
                
                let oldRandomPeople = self.randomPeople
                self.randomPeople = newRandomPeople.sorted(by: { (lhs, rhs) -> Bool in
                    guard let lhsName = lhs.name, let rhsName = rhs.name else { return false }
                    return lhsName < rhsName
                })
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    
                }
                
                for oldPerson in oldRandomPeople {
                    context.delete(oldPerson)
                }
                
                do {
                    try context.save()
                } catch {
                    print("Error saving context: \(error)")
                    context.rollback()
                }
                
            }
            
        }
        
    }
    
    
    func presentFetchErrorAlertForError(error: WebError?) {
        
        var message : String
        
        if let error = error {
            message = WebError.reasonForError(error: error)
        } else {
            message = "An unknown error occurred"
        }
        
        let alert = UIAlertController(title: NSLocalizedString("Ooops!", comment: "Title for error message"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK button title"), style: .cancel, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        present(alert, animated: true, completion: nil)
        
    }

    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
 
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return randomPeople.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //I feel that it is okay for force cast tableview cells in this instance. If I don't have a cell of this type with this reuseId, I want the app to crash right away so I will know.
        let cell = tableView.dequeueReusableCell(withIdentifier: PeopleTableViewController.kPersonCellIdentifier, for: indexPath) as! PeopleTableViewCell
        
        cell.person = randomPeople[indexPath.row]
        
        return cell
   
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let numberOfPeopleVC = segue.destination as? NumberOfPeopleTableViewController {
            numberOfPeopleVC.numberOfPeopleDelegate = self
        }
    }
 

}

extension PeopleTableViewController : NumberOfPeopleDelegate {
    func numberOfPeopleChanged() {
        self.fetchRandomPeople()
    }
}

class PeopleTableViewCell : UITableViewCell {
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    
    var person : Person? {
        didSet {
            guard let person = person else { return }
            nameLabel.text = person.name
            emailLabel.text = person.email
            phoneLabel.text = person.phone
            guard let thumbnail = person.thumbnail else { return }
            
            if let imageData = thumbnail.imageData  {
                
                thumbnailImageView.image = UIImage(data : imageData as Data)
                
            } else {
               
                ThumbnailImageDownloader.dowloadThumbnailImageForThumnail(thumbnail : thumbnail) { (image, thumbnailID) in
                    
                    DispatchQueue.main.async {
                        if let image = image, self.person?.thumbnail?.objectID == thumbnailID {
                            self.thumbnailImageView.image = image
                        }
                    }
                 
                }
            }
            
            
            
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        thumbnailImageView.layer.masksToBounds = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = ""
        emailLabel.text = ""
        phoneLabel.text = ""
        thumbnailImageView.image = UIImage()
    }
    
}
