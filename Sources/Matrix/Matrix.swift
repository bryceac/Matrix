import Foundation

/**
 class that represents Matrices of fixed constraints.
 */
public struct Matrix<T> {
    
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
    
    // MARK: Functions

    /**
     method to check if given index is valid
     - Parameters:
        - parameter row: row index.
        - parameter column: column idex.
     - Returns: Boolean that specifies whether index is valid.
     - Note: method is only available in methods and subscripts in the class.
     */
    private func isValidIndex(row: Int? = nil, column: Int? = nil) -> Bool {
        // variable to hold condition results
        var isValid = false
        
        /*
         attempt to unwrap column, and if successful check if it is valid.
         
         Otherwise, check if the row is valid
         */
        if let column = column, let row = row {
            
            // call self to check row and then check the column
            isValid = isValidIndex(row: row) && isValidIndex(column: column)
        } else if let row = row {
            isValid = row >= 0 && row < ROWS
        } else if let column = column {
            isValid = column >= 0 && column < COLUMNS
        }
        
        // return results
        return isValid
    }
    
    /**
    shuffles elements in grid in place.
    */
    public mutating func shuffle() {
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
} // end structure

// MARK: Extensions

// extension to custom how Matrix is displayed
extension Matrix: CustomStringConvertible {
    public var description: String {
        var content = ""
        
        for row in grid {
            for (index, item) in row.enumerated() {
                content += index != row.indices.last! ? "\(item)\t" : "\(item)\r\n"
            }
        }
        return content
    }
}

// extension to make class automatically conform to Equatable
extension Matrix: Equatable where T: Equatable {
    public static func ==(lhs: Matrix, rhs: Matrix) -> Bool {
        return lhs.ROWS == rhs.ROWS && lhs.COLUMNS == rhs.COLUMNS
    }
} // end extension

// extension to automatically conform to Hashable
extension Matrix: Hashable where T: Hashable {}

// extension to automatically conform to Codable
extension Matrix: Codable where T: Codable {
    /**
        enumeration that helps in specifies the keys used in serialization and deserialization
     */
    public enum CodingKeys: String, CodingKey {
        case grid
    }

    /**
     Initializer used for decode Matrix object from a Data object.
     - Returns: Matrix object from a Data Object.
     - Note: This method is not be used directly, as the appropriate Encoder object uses the method.
     */
    public init(from decoder: Decoder) throws {
        // create container with certain keys
        let CONTAINER = try decoder.container(keyedBy: CodingKeys.self)
        
        // try to grab object with specified key
        let GRID = try CONTAINER.decode([[T]].self, forKey: .grid)
        
        // create Matrix object
        self.init(withGrid: GRID)
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
} // end Codable extension

// extension to make type a true collection
extension Matrix: RandomAccessCollection, MutableCollection {
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

        /**
        default initializer
        */
        public init(row: Int, column: Int) {
            (self.row, self.column) = (row, column)
        }
        
        public static func ==(lhs: Index, rhs: Index) -> Bool {
            return lhs.row == rhs.row && lhs.column == rhs.column
        }
        
        public static func < (lhs: Index, rhs: Index) -> Bool {
            return lhs.row < rhs.row || lhs.column < rhs.column
        }
    } // end struct

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
        guard i == startIndex && distance.signum() == 1 || i == endIndex && distance.signum() == -1 || i != startIndex || i != endIndex else {
            return i
        }

        var index = i

        // base direction on whether distance is positive or negative
        switch distance.signum() {
            case 1:
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
            case -1:
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
            default: ()
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
     first Index in collection.
     */
    public var startIndex: Index { return Index(row: 0, column: 0) }
    
    /**
     ending index in collection.
     - Note: value is always going to be out of bounds.
     */
    public var endIndex: Index { return Index(row: ROWS, column: 0) }

    // subscript needed to make it possible to use an index object
    public subscript(position: Index) -> T {
        get {
            return self[position.row, position.column]
        }
        
        set {
            self[position.row, position.column] = newValue
        }
    } // end subscript

    // subscript that allows elements in column to be grabbed.
    public subscript(column column: Int) -> [T] {
        get {
            guard isValidIndex(column: column) else {
                fatalError("Index out of Bounds")
            }

            // constant that holds indices with the specified column
            let COLUMN_INDICES = indices.filter { $0.column == column }
        
            // return elements in column
            return COLUMN_INDICES.map {
                self[$0]
            }
        }
    }
}

