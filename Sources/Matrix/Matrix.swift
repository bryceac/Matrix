import Foundation

/**
 class that represents Matrices of fixed constraints
 */
public class Matrix<T: Codable>: Codable {
    
    // MARK: Properties
    /**
        - Returns: number rows in Matrix.
     */
    public let ROWS: Int
    
    /**
            - Returns: number of columns in Matrix
     */
    public let COLUMNS: Int
    
    /**
        Houses the actual Matrix.
        - Returns: Matrix of the initialized type
     */
    public var grid: [[T]] = []
    
    // MARK: Enumerations
    
    /**
        enumeration that helps in specifies the keys used in serialization and deserialization
     */
    public enum CodingKeys: String, CodingKey {
        case grid
    }
    
    // MARK: Initializers
    
    // defsault initializer
    
    /**
     Initializer that can be used to create a Matrix with a particular value.
     
     - Parameters:
        - parameter rows: the number of rows.
        - parameter columns: the number of columns.
        - parameter defaultValue: the value to use.
     - Returns: Matrix whose rows and columns all contain the same value.
     */
    public init(withRows rows: Int, columns: Int, andDefaultValue defaultValue: T) {
        
        // set the properties
        (ROWS, COLUMNS) = (rows, columns)
        
        grid = [T](repeating: defaultValue, count: rows*columns).chunked(into: columns)
    }
    
    /**
     Initializer that can create a Matriz from a predefined 2D array.
     - Parameters:
        - parameter grid: the 2D array to use in Matrix
     - Returns: Matrix object made of the specified 2D array
     */
    public init(withGrid grid: [[T]]) {
        
        // grab the longest row from 2D array
        let LONGEST_ROW = grid.max(by: { $0.count < $1.count })!
        
        // set properties of Matrix
        (ROWS, COLUMNS, self.grid) = (grid.count, LONGEST_ROW.count, grid)
    }
    
    /**
     Initializer used for decode Matrix object from a Data object.
     - Returns: Matrix object from a Data Object.
     - Note: This method is not be used directly, as the appropriate Encoder object uses the method.
     */
    public required convenience init(from decoder: Decoder) throws {
        // create container with certain keys
        let CONTAINER = try decoder.container(keyedBy: CodingKeys.self)
        
        // try to grab object with specified key
        let GRID = try CONTAINER.decode([[T]].self, forKey: .grid)
        
        // create Matrix object
        self.init(withGrid: GRID)
    }
    
    // MARK: Functions

    /**
    class method that allows Matrices to be loaded from a file.
    - parameter path: the URL for the JSON file.
    - Returns: if File cannot be loaded or parsed, nil will be returned.
    - Note: This method is not to be used with remote files, due to how it grabs the data
    */
    public class func load(from path: URL) -> Matrix<T>? {
        
        // create JSON decoder object
        let JSON_DECODER = JSONDecoder()

        // attempt to parse JSON
        guard let JSON_DATA = try? Data(contentsOf: path), let MATRIX = try? JSON_DECODER.decode(Matrix<T>.self, from: JSON_DATA) else { return nil }

        // return decoded Matrix object
        return MATRIX
    }
    
    /**
     method used to encode Matrix object to data
     - Note: This function is not to be used directly, since the appropriate Encoder object uses this method.
     */
    public func encode(to encoder: Encoder) throws {
        
        // create a container with specified keys
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // attempt to add grid to container
        try container.encode(grid, forKey: .grid)
    }

    /**
    save JSON to a particular path.
    - parameter path: file path
    */
    public func save(to path: URL) {

        // create JSONEncoder object
        let JSON_ENCODER = JSONEncoder()

        // beautify the output, for easy reading
        JSON_ENCODER.outputFormatting = .prettyPrinted

        // attempt to encode the Matrix
        guard let ENCODED_MATRIX = try? JSON_ENCODER.encode(self) else { return }

        // attempt to write data to path
        try? ENCODED_MATRIX.write(to: path, options: .atomic)
    }
    
    /**
     method to check if given index is valid
     - Parameters:
        - parameter row: row index.
        - parameter column: column idex.
     - Returns: Boolean that specifies whether index is valid.
     - Note: method is only available in methods and subscripts in the class.
     */
    private func isValidIndex(row: Int, column: Int? = nil) -> Bool {
        // variable to hold condition results
        var isValid = true
        
        /*
         attempt to unwrap column, and if successful check if it is valid.
         
         Otherwise, check if the row is valid
         */
        if let column = column {
            
            // call self to check row and then check the column
            isValid = isValidIndex(row: row) && column >= 0 && column < COLUMNS
        } else {
            isValid = row >= 0 && row < ROWS
        }
        
        // return results
        return isValid
    }
    
    // MARK: Subscripts
    
    // subscripts that allow data to be retrieved in a coordinate manner
    public subscript(row: Int) -> [T] {
        get {
            guard isValidIndex(row: row) else {
                fatalError("Index out of Bounds.")
            }
            
            return grid[row]
        }
        
        set {
            guard isValidIndex(row: row) else {
                fatalError("Index out of Bounds.")
            }
            
            grid[row] = newValue
        }
    } // end subscript
    
    public subscript(row: Int, column: Int) -> T {
        get {
            guard isValidIndex(row: row, column: column) else {
                fatalError("Index out of Bounds")
            }
            
            return grid[row][column]
        }
        
        set {
            guard isValidIndex(row: row, column: column) else {
                fatalError("Index out of Bounds")
            }
            
            grid[row][column] = newValue
        }
    } // end subscript
} // end class

// MARK: Extensions

// extension to make class conform to CustomStringConvertible
extension Matrix: CustomStringConvertible {
    public var description: String {
        var content = ""
        
        for row in grid {
            for (index, item) in row.enumerated() {
                content += index != row.indices.last! ? "\(item)" : "\(item)\r\n"
            }
        }
        return content
    }
} // end extension

// extension to make class automatically conform to Equatable
extension Matrix: Equatable where T: Equatable {
    public static func ==(lhs: Matrix, rhs: Matrix) -> Bool {
        return lhs.ROWS == rhs.ROWS && lhs.COLUMNS == rhs.COLUMNS
    }
} // end extension

// extension to make class automatically conform to Hashable
extension Matrix: Hashable where T: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ROWS)
        hasher.combine(COLUMNS)
        hasher.combine(grid)
    }
} // end extension

/*extension to make class a mutable colllection that can be traversed from first to last or vice versa. */
extension Matrix: BidirectionalCollection, MutableCollection {
    
    /**
     Position of a Matrix Element
     */
    public struct Index: Comparable {
        /**
         row index
         */
        public var row: Int
        
        /**
         column index
         */
        public var column: Int
        
        public static func ==(lhs: Index, rhs: Index) -> Bool {
            return lhs.row == rhs.row && lhs.column == rhs.column
        }
        
        public static func < (lhs: Index, rhs: Index) -> Bool {
            return lhs.row < rhs.row || lhs.column < rhs.column
        }
    } // end struct
    
    // MARK: Computed Properties
    
    /**
     first Index in collection
     */
    public var startIndex: Index { return Index(row: 0, column: 0) }
    
    /**
     ending index in collection.
     - Note: value is always going to be out of bounds.
     */
    public var endIndex: Index { return Index(row: ROWS, column: 0) }
    
    // MARK: Functions
    
    /**
     retrieve an index preceeding a given index.
     */
    public func index(before i: Index) -> Index {
        
        // store index in variable
        var index = i
        
        // check if column is 0 and make adjustments accordingly
        if index.column > 0 {
            index.column -= 1
        } else {
            index.row -= 1
            index.column = COLUMNS-1
        }
        
        // return new index
        return index
    } // end method
    
    /**
     retrieve index after a given index.
     */
    public func index(after i: Index) -> Index {
        
        // store index in variable
        var index = i
        
        // check if column is less than the maximum number of columns and adjust accordingly
        if index.column < COLUMNS-1 {
            index.column += 1
        } else {
            index.row += 1
            index.column = 0
        }
        
        // return new index
        return index
    } // end method
    
    // MARK: Subscripts
    
    // subscript needed to make it possible to use an index object
    public subscript(position: Index) -> T {
        get {
            return self[position.row, position.column]
        }
        
        set {
            self[position.row, position.column] = newValue
        }
    } // end subscript
    
} // end extension

// extension that will add things to class, regardless of what the type conforms to
extension Matrix {
    /**
     retrieve elements in a given column.
     - Parameter c: the column number
     - Precondition: c must be a value between 0 and 1 less than the total number of columns.
     - Returns: Array of elements in a given column.
     */
    public func column(_ c: Int) -> [T] {
        guard c >= 0 && c < COLUMNS else {
            preconditionFailure("column number must be between 0 and \(COLUMNS-1).")
        }
        
        // constant that holds indices with the specified column
        let COLUMN_INDICES = indices.filter { $0.column == c }
        
        // create variable to hold column data
        var column: [T] = []
        
        // add elements to column variable
        for index in COLUMN_INDICES {
            column.append(self[index])
        }
        
        // return column elements
        return column
    } // end function
} // end extension

