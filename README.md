# iOS-Swift-SQLite-DBHandler
A swift file to handle SQLITE local database functionalities like CREATE, INSERT, UPDATE and DELETE 

Remove the below code before using from **init()** method. It is a sample code on how to access the methods in this file 

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
