//
//  ViewController.swift
//  ContactListApp
//
//  Created by Ahmed Fayeq on 23/11/2021.
//

import UIKit
import SQLite3

class ViewController: UITableViewController {
    var db : OpaquePointer?
    var contactsId  = [Int32]()
    var contacts    = [String]()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setup()
    }
    
    func setup(){
        db = openDatabase()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showAlertController))
        refreshTableView()
    }
    
    func openDatabase() -> OpaquePointer? {
        var dbOpaquePointer: OpaquePointer?
        let fileUrl = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("Contacts.sqlite")
        if sqlite3_open(fileUrl?.path, &dbOpaquePointer) == SQLITE_OK {
            print("successfully opened connection to db")
            return dbOpaquePointer
        }else {
            showErrorMsg(msg: "unable to open db connection")
            return nil
        }
    }
    
    func createContactsTable(db: OpaquePointer?){
        let createTableString = """
        CREATE TABLE Contacts(Id INT PRIMARY KEY NOT NULL,
        Name CHAR(255));
        """
        //1
        var createTableStatement: OpaquePointer?
        //2
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK{
            //3
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("Contacts Table Created")
            }else {
                print("Contacts table is not created")
            }
        }else {
            showErrorMsg(msg: "Create table statement is not prepared")
        }
        //4
        sqlite3_finalize(createTableStatement)
    }
    
    func insert(id: Int32, name: String, db: OpaquePointer?){
        let insertStatementString = "INSERT INTO Contacts (Id, Name) VALUES (?, ?);"
        var insertStatement: OpaquePointer?
        //1
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK{
            //2
            sqlite3_bind_int(insertStatement, 1, id)
            //3
            sqlite3_bind_text(insertStatement, 2, name, -1, nil)
            //4
            if sqlite3_step(insertStatement) == SQLITE_DONE{
                print("row successfully inserted")
                self.refreshTableView()
            }else{
                showErrorMsg(msg: "User with this Id already exists")
            }
        }else{
            showErrorMsg(msg: "insert statement is not prepared")
        }
        sqlite3_finalize(insertStatement)
    }
    
    func refreshTableView(){
        contacts    = []
        contactsId  = []
        query(db: db)
        self.tableView.reloadData()
    }
    
    func query(db: OpaquePointer?){
        let queryStatementString = "SELECT * FROM Contacts Order By Id;"
        var queryStatement: OpaquePointer?
        //1
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK{
            //2
            while sqlite3_step(queryStatement) == SQLITE_ROW{
                //3
                let id = sqlite3_column_int(queryStatement, 0)
                //4
                guard let queryResultCol1 = sqlite3_column_text(queryStatement, 1) else{
                    print("query result is nil")
                    return
                }
                //5
                contacts.append(String(cString: queryResultCol1))
                contactsId.append(id)
            }
        }else{
            let errorMsg = String(cString: sqlite3_errmsg(db))
            showErrorMsg(msg: "Query is not prepared \(errorMsg)")
        }
        sqlite3_finalize(queryStatement)
    }
    
    func delete(db: OpaquePointer?, Id: Int32){
        let deleteStatementString = "DELETE FROM Contacts WHERE Id = \(Id);"
        var deleteStatment: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatment, nil) == SQLITE_OK{
            if sqlite3_step(deleteStatment) == SQLITE_DONE{
                print("Row deleted successfully")
                self.refreshTableView()
            }else{
                showErrorMsg(msg: "Couldn't delete row")
            }
        }else{
            showErrorMsg(msg: "delete statement couldn't be prepared")
        }
        sqlite3_finalize(deleteStatment)
    }
    
    @objc func showAlertController(){
        let addContactAlertController = UIAlertController(title: "Add new contact", message: nil, preferredStyle: .alert)
        addContactAlertController.addTextField { (tf) in
            tf.placeholder = "Enter Id"
        }
        addContactAlertController.addTextField { (tf) in
            tf.placeholder = "Enter Name"
        }
        let submitButton = UIAlertAction(title: "Submit", style: .default) { [weak self, weak addContactAlertController] action in
            guard let Id    = addContactAlertController?.textFields?[0].text else { return }
            guard let name  = addContactAlertController?.textFields?[1].text else { return }
            print(Id)
            print(name)
            guard let idAsInt = Int32(Id) else {return}
            self?.insert(id: idAsInt, name: name , db: self?.db)
            self?.query(db: self?.db)
        }
        addContactAlertController.addAction(submitButton)
        present(addContactAlertController, animated: true)
    }
    
    func showErrorMsg(msg: String){
        let ac = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Ok", style: .default))
        present(ac, animated: true)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        contacts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactCell")
        cell?.textLabel?.text = "\(contactsId[indexPath.row])) \(contacts[indexPath.row])"
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .normal, title: "Delete") { [weak self] (action, view, bool) in
            //delete action code
            self?.delete(db: self?.db, Id: self?.contactsId[indexPath.row] ?? 0)
        }
        deleteAction.backgroundColor = .red
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
}
