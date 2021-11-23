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
        createContactsTable(db: db)
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
}

