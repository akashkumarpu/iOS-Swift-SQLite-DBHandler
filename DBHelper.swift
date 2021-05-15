//
//  DBHelper.swift
//  Equipment Inventory Manager
//
//  Created by akash on 11/05/21.
//

import Foundation
import SQLite3

class DBHelper
{
    // Shared instance for class
    static let sharedDBHelper = DBHelper()
    
    //Declarations
    var db:OpaquePointer?
    var dbPath = String()
    
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------
    init()
    {
        db = openDatabase()
        createTable(tableName: DBConstants.USER_TABLE, schema: DBConstants.USER_SCHEMA)
        let result = insert(records: DBConstants.insert_data, tableName: DBConstants.USER_TABLE)
        print("Insert result = " + String(result))
        if (result){
            let selectResult = selectData(columns: ["UserName", "Pin", "Rating", "IsActive"], whereClause: [], tableName: DBConstants.USER_TABLE, schema: DBConstants.USER_SCHEMA)
            print("Select query result")
            print(selectResult)
            let updateResult = updateRecords(records: [["IsActive" : false]], whereClause: ["Rating = 9.5"], tableName: DBConstants.USER_TABLE, schema: DBConstants.USER_SCHEMA)
            if (updateResult){
                let selectResult2 = selectData(columns: ["UserName", "Pin", "Rating", "IsActive"], whereClause: [], tableName: DBConstants.USER_TABLE, schema: DBConstants.USER_SCHEMA)
                print("Select query result aafter update")
                print(selectResult2)
            }
        }
    }
    
    //MARK: - COMMON METHODS
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------
    func openDatabase() -> OpaquePointer?
    { // Method to create data base
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent(DBConstants.DB_NAME)
        dbPath = fileURL.path
        var db: OpaquePointer? = nil
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK
        {
            print("error opening database")
            return nil
        }
        else
        {
            print("Successfully opened connection to database at \(DBConstants.DB_NAME)")
            return db
        }
    }
    
    
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------
    func createTable(tableName: String, schema: [[String: String]])  // Method to create a new table
    {
        let createTableString = "CREATE TABLE IF NOT EXISTS " + tableName + " (" + columnString(columns: schema) + ")"
        var createTableStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK
        {
            if sqlite3_step(createTableStatement) == SQLITE_DONE
            {
                print(tableName + " table created.")
            } else {
                print(tableName + " table could not be created.")
            }
        } else {
            print("CREATE TABLE statement could not be prepared.")
        }
        sqlite3_finalize(createTableStatement)
    }
    
    
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------
    func insert(records:[[String:Any]], tableName:String) -> Bool  // Method to insert new records to table
    {
        var columns = [String]()
        if (records.count > 0) {
            let record: NSDictionary = records[0] as NSDictionary;
            for columnString in record.allKeys {
                columns.append(columnString as! String)
            }
            var sqlString: String
            sqlString = "INSERT INTO " + tableName + " " + "(" + columns.joined(separator: ", ") + ")" + " VALUES"
            for i in 0..<columns.count {
                if (i == 0)
                {
                    sqlString = sqlString + " (?, ";
                }
                else if (i == columns.count - 1)
                {
                    sqlString = sqlString + "?)";
                }
                else
                {
                    sqlString = sqlString + "?, ";
                }
            }
            var insertStatement: OpaquePointer? = nil
            if sqlite3_prepare_v2(db, sqlString, -1, &insertStatement, nil) == SQLITE_OK {
                for rec in records {
                    let record1 = rec as NSDictionary
                    var values = [Any]()
                    for columnString in record.allKeys {
                        if (record1[columnString] is String){
                            var stringVal: String = record1[columnString] as! String
                            stringVal = stringVal.replacingOccurrences(of: "'", with: "")
                            stringVal = stringVal.trimmingCharacters(in: CharacterSet.whitespaces)
                            values.append(stringVal)
                        }
                        else if (record1[columnString] is Int){
                            let numVal: NSNumber = record1[columnString] as! NSNumber
                            values.append(numVal)
                        }
                        else if (record1[columnString] is Double){
                            let numVal: Double = record1[columnString] as! Double
                            values.append(numVal)
                        }
                        else if (record1[columnString] is Bool){
                            let boolVal: Bool = record1[columnString] as! Bool
                            values.append(boolVal)
                        }
                    }
                    for  columnCount in 0..<values.count {
                        if (values[columnCount] is String){
                            sqlite3_bind_text(insertStatement, Int32(columnCount + 1), (values[columnCount] as! NSString).utf8String, -1, nil)
                        }
                        else if (values[columnCount] is Int || values[columnCount] is Bool){
                            sqlite3_bind_int(insertStatement, Int32(columnCount + 1), Int32(truncating: values[columnCount] as! NSNumber))
                        }
                        else if (values[columnCount] is Double){
                            sqlite3_bind_double(insertStatement,Int32(columnCount + 1) , values[columnCount] as! Double)
                        }
                    }
                    if (sqlite3_step(insertStatement) != SQLITE_DONE) {
                        sqlite3_finalize(insertStatement)
                        sqlite3_close(db)
                        return false
                    }
                    sqlite3_clear_bindings(insertStatement)
                    sqlite3_reset(insertStatement)
                }
                sqlite3_finalize(insertStatement)
            }else{
                sqlite3_finalize(insertStatement)
                sqlite3_close(insertStatement)
                return false;
            }
        }
        return true
    }
    
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------
    func selectData(columns: Array<String>, whereClause: Array<Any>, tableName: String, schema: [[String: String]]) -> Array<Any> // Method to select data from tables
    {
        var records = [[String: Any]]()
        let query: String = selectQueryyString(columns: columns, whereClause: whereClause, tableName: tableName)
        var selectStatement: OpaquePointer? = nil
        if (sqlite3_prepare_v2(db, query, -1, &selectStatement, nil) == SQLITE_OK) {
            while (sqlite3_step(selectStatement) == SQLITE_ROW){
                var dictionary = [String: Any]();
                for  i in 0..<columns.count {
                    let columnName: String =  String(cString: sqlite3_column_name(selectStatement, Int32(i)))
                    var columnValue: String = "";
                    if(sqlite3_column_text(selectStatement, Int32(i)) != nil ){
                        columnValue =  String(cString: sqlite3_column_text(selectStatement, Int32(i)));
                    }
                    if(columnValue == "<null>"){
                        columnValue = "";
                    }
                    if (columnName.count > 0) {
                        dictionary.updateValue(columnValue, forKey: columnName)
                    }
                }
                //check for dictionary has values and add to array
                if (!dictionary.isEmpty){
                    records.append(dictionary)
                }
            }
            sqlite3_reset(selectStatement);
            sqlite3_finalize(selectStatement);
        }
        sqlite3_close(db);
        return records;
    }
    
    
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------
    func updateRecords(records: [[String: Any]], whereClause: Array<Any>, tableName: String, schema: [[String: String]]) -> Bool
    {
        var returnVal = Bool()
        if sqlite3_open(dbPath, &db) == SQLITE_OK
        {
        var updateStatement: OpaquePointer? = nil
        for record in records {
            let query: String = "UPDATE " + tableName + " SET " + updateValuesString(values: record as NSDictionary) + " WHERE " + whereClauseString(whereClause: whereClause)
            if (sqlite3_prepare_v2(db, query, -1, &updateStatement, nil) == SQLITE_OK){
                if(sqlite3_step(updateStatement) == SQLITE_DONE){
                    returnVal = true
                }
                else{
                    returnVal = false
                }
            }
            else{
                returnVal = false
            }
        }
        sqlite3_close(db);
        }
        return returnVal;
    }
    
    
    //MARK: - HELPER METHODS
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------
    func selectQueryyString(columns: Array<String>, whereClause: Array<Any>, tableName: String) -> String {
        var toFormWhereClauseFromOuterFunction: Bool = true;
        var query: String = "SELECT "  + columns.joined(separator: ", ") + " FROM " +  tableName
        if (whereClause.count > 0) {
            if (whereClause.count == 1) {
                if (whereClause.last is String) {
                    let upperCaseString:  String = ((whereClause.last) as! String).uppercased()
                    if (upperCaseString.hasPrefix("JOIN")){
                        toFormWhereClauseFromOuterFunction = false;
                        
                    }
                }
            }
            //
            if (toFormWhereClauseFromOuterFunction) {
                query = query + " WHERE " + whereClauseString(whereClause: whereClause)
            }
            else{
                query = query + ((whereClause.last) as! String)
            }
        }
        return query;
    }
    
    
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------
    func updateValuesString(values: NSDictionary) -> String {
        var columns = [String]()
        for  key in values.allKeys {
            if (values[key] is String) {
                columns.append(key as! String + " = " + (values[key] as! String).replacingOccurrences(of: "'", with: "''"))
            }
            if (values[key] is Bool) {
                if(values[key] as! Bool){
                columns.append(key as! String + " = 1")
                }
                else{
                    columns.append(key as! String + " = 0")
                }
            }
            else {
                columns.append(key as! String + " = " + (values[key] as! String))
            }
        }
        return columns.joined(separator: ", ")
    }
    
    
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------
    func whereClauseString(whereClause: Array<Any>) -> String {
        var _whereClause = [String]()
        for element in whereClause {
            if (element is NSDictionary){
                let elementCopy = element as! NSDictionary
                let key: String = (elementCopy.allKeys).last as! String
                if (elementCopy[key] is String) {
                    _whereClause.append(key + " = " + (elementCopy[key] as! String).replacingOccurrences(of: "'", with: ""))
                }
                else {
                    _whereClause.append(key + " = " + (elementCopy[key] as! String))
                }
            }
            else if (element is String){
                _whereClause.append(element as! String);
            }
            else if (element is Array<Any>){
                _whereClause.append(whereClauseString(whereClause: whereClause))
            }
        }
        return _whereClause.joined(separator: " ")
    }
    
    
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------
    func columnString (columns: [[String: String]] ) -> String {
        var columnsArray = [String]()
        for column in columns {
            var col_str = column["COLUMN"]! + " " + column["TYPE"]!
            col_str =  column["IS_PRIMARY"] == "YES" ? col_str + " " + DBConstants.PK : col_str
            col_str =  column["IS_NOTNULL"] == "YES" ? col_str + " " + DBConstants.NOT_NULL : col_str
            columnsArray.append(col_str)
        }
        let joined = columnsArray.joined(separator: ", ")
        return joined
    }
    
}
