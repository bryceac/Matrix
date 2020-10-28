import Foundation

/**
protocol that ensures object will have subscripts and functions for matrices.

This is not to be conformed to directly, as its purpose is allow extensions that tackle matrices of matrices.
*/
public protocol MatrixProtocol: Codable, RandomAccessCollection, MutableCollection {
    var COLUMNS: Int { get }
	var ROWS: Int { get }
    subscript(row: Int) -> [Element] { get set }
    subscript(row: Int, column: Int) -> Element { get set }
    subscript(column column: Int) -> [Element] { get }
}

/**
 class that represents Matrices of fixed constraints.
 */
public struct Matrix<T: Codable>: CustomStringConvertible, MatrixProtocol {
	
	public typealias Iterator = MatrixIterator<T>
    public typealias Index = MatrixIndex
    
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
                content += index != row.indices.last! ? "\(item)\t" : "\(item)\r\n"
            }
        }
        return content
    }
	
	/**
	number of elements in collection.
	*/
	public var count: Int {
		return grid.joined().count
	}
	
    // MARK: Enumerations
    
    /**
        enumeration that helps in specifying the keys used in serialization and deserialization
     */
    private enum CodingKeys: String, CodingKey {
        case grid
    }

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

        Index.maxRowNumber = ROWS
        Index.maxColumnNumber = COLUMNS-1
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

        Index.maxRowNumber = ROWS
        Index.maxColumnNumber = COLUMNS-1
    }
    
    /**
     Initializer used for decode Matrix object from a Data object.
     - Returns: Matrix object from a Data Object.
     - Note: This method is not be used directly, as the appropriate Decoder object uses the method.
     */
    public init(from decoder: Decoder) throws {
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
    - Returns: Matrix object.
    - Note: This method is not to be used with remote files, due to how it grabs the data
    */
    public static func load(from path: URL) throws -> Matrix<T> {
        
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
    - Throws: an error regarding the writing of the file, in the event it fails to save, or an `EncodigError`.
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
    private func isValidIndex(row: Int? = nil, column: Int? = nil) -> Bool {
        // variable to hold condition results
        var isValid = true
        
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
     retrieve an index preceeding a given index.
     */
    public func index(before i: Index) -> Index {
        guard i != startIndex else { return startIndex }
        return i.advanced(by: -1)
    } // end method
    
    /**
     retrieve index after a given index.
     */
    public func index(after i: Index) -> Index {
        guard i != endIndex else { return i }
        return i.advanced(by: 1)
    } // end method

    /**
    get an index by offsetting a given index.
    - Paramters:
        - paramter i: index to start with.
        - parameter distance: the offset.
    - Returns: Index with the desired offset.
    - Precondition: distance must be negative if i is endIndex and positive if i is startIndex.
    - Note: if specified offset could possibly go out of bounds, either startIndex or endIndex will be returned.
    */
    public func index(_ i: Index, offsetBy distance: Int) -> Index {
        guard case startIndex...endIndex = i else { return i < startIndex ? startIndex : endIndex }
        guard i >= startIndex && distance.signum() == 1 || i <= endIndex && distance.signum() == -1 else {
            if i == startIndex {
                preconditionFailure("distance must be a positive value if the given index is the startIndex")
            } else {
                preconditionFailure("distance must be negative if the given index is the endIndex")
            }
        }

        return i.advanced(by: distance)
    } // end function
    
    /**
    shuffles elements in grid in place.
    */
    public mutating func shuffle() {
        grid = self.shuffled().chunked(into: COLUMNS)
    }
	
	/**
	function to produce iterator for collection
	*/
	public func makeIterator() -> Iterator {
		return MatrixIterator(withMatrix: self)
	}
    
    // MARK: Subscripts
    
    /**
    retrieve elements in a specified row or manipulate a row.
    */
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
    
    /**
    retrieve elements in a column.
    */
    public subscript(column column: Int) -> [T] {
        get {
            guard isValidIndex(column: column) else {
                fatalError("Index out of Bounds.")
            }
            
            // constant that holds indices with the specified column
            let COLUMN_INDICES = indices.filter { $0.column == column }
        
            // return elements in column
            return COLUMN_INDICES.map {
                self[$0]
            }
        }
    } // end subscript
    
    /**
    retrieve or set elements at a particular coordinate.
    */
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
    
    /**
    retrieve or set element at a specified position.
    */
    public subscript(position: Index) -> T {
        get {
            return self[position.row, position.column]
        }
        
        set {
            self[position.row, position.column] = newValue
        }
    } // end subscript
} // end struct

// MARK: Extensions

// extension to make class automatically conform to Equatable
extension Matrix: Equatable where T: Equatable {
    public static func ==(lhs: Matrix, rhs: Matrix) -> Bool {
        return lhs.ROWS == rhs.ROWS && lhs.COLUMNS == rhs.COLUMNS && lhs.grid == rhs.grid
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

// extension to add functions that only exist when Matrix contains other matrices.
extension Matrix where T: MatrixProtocol {
    /// number of rows in mtrix of matrixa
	public var totalRows: Int {
		var total = 0
		
		for row in grid {
			
			// find matrix with most rows in row
			let MATRIX_WITH_MOST_ROWS = row.max { $0.ROWS < $1.ROWS }!
			
			// add row count to grand total
			total += MATRIX_WITH_MOST_ROWS.ROWS
		}
		
		return total
	}
	
	/// number of columns in matrix of matrix
	public var totalColumns: Int {
		
		// create dictionary to hold column counts
		var columnCounts: [Int: Int] = [:]
		
		// variable to hold maximum number of columns
		var total = 0
		
		// count up the columns in each row and add it to the dictionary
		for (index, row) in grid.enumerated() {
			columnCounts[index] = row.reduce(0) { $0 + $1.COLUMNS }
		}
		
		// determine which key has the highest value and set that as the grand total
		total = columnCounts.max { a, b in
			a.value < b.value
		}!.value
		
		return total
	}

	/**
	retrieve items in a particular row.
	- Parameter y: the row index.
	- Precondition: specified number must be smaller than the total number of rows, but not less than 0.
	- Returns: 2D array of all elements in a row.
	*/
	public subscript(y y: Int) -> [[T.Element]] {
		guard case 0..<totalRows = y else {
			preconditionFailure("index must be between 0 and \(totalRows-1)")
		}
	
		let COORDINATES = y.quotientAndRemainder(dividingBy: ROWS)
		
		return self[COORDINATES.quotient].map { $0[COORDINATES.remainder] }
	}
	
	/**
	retrieve items in a particular column.
	- Parameter x: the column index.
	- Precondition: specified number must be less than the total number of columns, but not less than 0.
	- Returns: 2D array of all elements in a column.
	*/
	public subscript(x x: Int) -> [[T.Element]] {
		guard case 0..<totalColumns = x else {
			preconditionFailure("index must be between 0 and \(totalColumns-1)")
		}
		
		let COORDINATES = x.quotientAndRemainder(dividingBy: COLUMNS)
		
		return self[column: COORDINATES.quotient].map { $0[column: COORDINATES.remainder] }
	}
} // end extension