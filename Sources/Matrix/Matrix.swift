import Foundation

/**
 class that represents Matrices of fixed constraints
 */
public class Matrix<T: Codable>: CustomStringConvertible, Codable, RandomAccessCollection, MutableCollection {
    
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

    /**
     first Index in collection.
     */
    public var startIndex: Index { return Index(row: 0, column: 0) }
    
    /**
     ending index in collection.
     - Note: value is always going to be out of bounds.
     */
    public var endIndex: Index { return Index(row: ROWS, column: 0) }

    public var description: String {
        var content = ""
        
        for row in grid {
            for (index, item) in row.enumerated() {
                content += index != row.indices.last! ? "\(item)" : "\(item)\r\n"
            }
        }
        return content
    }
    
    // MARK: Enumerations & Structures
    
    /**
        enumeration that helps in specifies the keys used in serialization and deserialization
     */
    public enum CodingKeys: String, CodingKey {
        case grid
    }

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
    
    // MARK: Initializers
    
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
    - Throws: any errors that crop up from reading files or decoding te JSON, which would be a `DecodingError`.
    - Returns: if File cannot be loaded or parsed, nil will be returned.
    - Note: This method is not to be used with remote files, due to how it grabs the data
    */
    public class func load(from path: URL) throws -> Matrix<T> {
        
        // create JSON decoder object
        let JSON_DECODER = JSONDecoder()

        // attempt to parse JSON
        let JSON_DATA = try Data(contentsOf: path)
        let MATRIX = try JSON_DECODER.decode(Matrix<T>.self, from: JSON_DATA)

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
    - Throws: an error regarding the writing of the file, in the event it fails to save.
    */
    public func save(to path: URL) throws {

        // create JSONEncoder object
        let JSON_ENCODER = JSONEncoder()

        // beautify the output, for easy reading
        JSON_ENCODER.outputFormatting = .prettyPrinted

        // attempt to encode the Matrix
        let ENCODED_MATRIX = try JSON_ENCODER.encode(self)

        // attempt to write data to path
        try ENCODED_MATRIX.write(to: path, options: .atomic)
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

    /**
     retrieve an index preceeding a given index.
     */
    public func index(before i: Index) -> Index {
        
        // make sure given indice comes after startIndex, otherwise return startIndex
        guard i > startIndex else {
            return startIndex
        }
        
        // store index in variable
        var index = i
        
        // check if column is 0 and make adjustments accordingly
        if index.column > 0 {
            index.column -= 1
        } else {
            index.row -= 1
            index.column = COLUMNS-1
        }
        
        return index
    } // end method
    
    /**
     retrieve index after a given index.
     */
    public func index(after i: Index) -> Index {

        // make sure index comes before endIndex, other return endIndex
        guard i < endIndex else {
            return endIndex
        }
        
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

    /**
    get an index by offsetting a given index.
    - Paramters:
        - paramter i: index to start with.
        - parameter distance: the offset.
    - Returns: Index with the desired offset.
    - Note: if specified offset could possibly go out of bounds, either startIndex or endIndex will be returned.
    */
    public func index(_ i: Index, offsetBy distance: Int) -> Index {

        /*
        make sure either offset is negative, if the given index is the endIndex, or positive if the startIndex.
        
        Otherwise return the index back without doing anything
        */
        guard i == startIndex && distance.signum() == 0 || i == endIndex && distance.signum() == -1 else {
            return i
        }

        var index = i

        // base direction off whether offset is negative or positive
        if distance.signum() == 0 {
            for _ in 1...distance {
                if index.column < COLUMNS-1 {
                    index.column += 1
                } else {
                    index.row += 1
                    index.column = 0
                }
            }

            // make sure index does not go beyond endIndex
            index = index > endIndex ? endIndex: index
        } else {

            // initiate loop based on the absolute value of the distance
            for _ in 1...abs(distance) {
                if index.column > 0 {
                    index.column -= 1
                } else {
                    index.row -= 1
                    index.column = COLUMNS-1
                }
            }

            // make sure index does not go beyond startIndex
            index = index < startIndex ? startIndex : index
        }

        // return index
        return index
    } // end function

    /**
    calculate the distance between two indices.
    - Parameters:
        - parameter start: index to start from
        - parameter end: index to compare with
    - Returns: a positive or negative integer, depending on which index was larger.
    */
    public func distance(from start: Index, to end: Index) -> Int {
        var steps = 0
        var index = start

        /* 
        Determine whether start index is greater than or less than end index.

        Depending on result, execute appropriate loop to get start index to be equal to the end, while counting iterations.
        */
        switch index {
            case let i where i < end:
                while index < end {
                    if index.column < COLUMNS-1 {
                        index.column += 1
                    } else {
                        index.row += 1
                        index.column = 0
                    }

                    steps += 1
                }
            case let i where i > end:
                while index > end {
                    if index.column > 0 {
                        index.column -= 1
                    } else {
                        index.row -= 1
                        index.column = COLUMNS-1
                    }
                    
                    // converts steps to negative
                    steps -= 1
                }
            default: ()
        }

        return steps
    } // end function

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

    /**
    shuffles elements in grid in place.
    */
    public func shuffle() {
        grid = self.shuffled().chunked(into: COLUMNS)
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

    // subscript needed to make it possible to use an index object
    public subscript(position: Index) -> T {
        get {
            return self[position.row, position.column]
        }
        
        set {
            self[position.row, position.column] = newValue
        }
    } // end subscript
} // end class

// MARK: Extensions

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

