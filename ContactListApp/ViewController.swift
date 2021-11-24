//
//  ViewController.swift
//  ContactListApp
//
//  Created by Ahmed Fayeq on 23/11/2021.
//

import UIKit
import SQLite3

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let db = openDatabase()
        //createContactsTable(db: db)
        //insert(id: 1, name: "FAYEQ", db: db)
        query(db: db)
    }
    
    func openDatabase() -> OpaquePointer? {
        var dbOpaquePointer: OpaquePointer?
        let fileUrl = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("Contacts.sqlite")
        if sqlite3_open(fileUrl?.path, &dbOpaquePointer) == SQLITE_OK {
            print("successfully opened connection to db")
            return dbOpaquePointer
        }else {
            print("unable to open db connection")
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
            print("Create table statement is not prepared")
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
            }else{
                print("couldn't insert row")
            }
        }else{
            print("insert statement is not prepared")
        }
        sqlite3_finalize(insertStatement)
    }
    
    func query(db: OpaquePointer?){
        let queryStatementString = "SELECT * FROM Contacts;"
        var queryStatement: OpaquePointer?
        //1
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK{
            //2
            if sqlite3_step(queryStatement) == SQLITE_ROW{
                //3
                let id = sqlite3_column_int(queryStatement, 0)
                //4
                guard let queryResultCol1 = sqlite3_column_text(queryStatement, 1) else{
                    print("query result is nil")
                    return
                }
                let name = String(cString: queryResultCol1)
                //5
                print("Query Result:")
                print("\(id) | \(name)")
            }else{
                print("Query returned no results")
            }
        }else{
            let errorMsg = String(cString: sqlite3_errmsg(db))
            print("Query is not prepared \(errorMsg)")
        }
        sqlite3_finalize(queryStatement)
    }
}

