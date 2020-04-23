import Foundation

/**
 Subclass of Matrix, used to represent Matrices within Matrics.
 
 Initializing:
 
 Initializing a SuperMatrix object is the name as its parent class.
 
 However, unlike a Matrix, it cannot be initialized with everything inferred, due to having two generics, so it can offer functionality that is useful to things like a Sudoku puzzles.
 
 Instead, initialization would be done like this:
 
 ~~~
 // create SuperMatrix object of a 3x3 grid, containing a premade Matrix
 let blocks = SuperMatrix<Matrix<Int>, Int >(withRows: 3, columns: 3, andDefaultValue: block)
 ~~~
 */
public class SuperMatrix<T: Codable, Element: Codable>: Matrix<T> {
    
    /**
    class method to load Super Matrices from JSON.
    - parameter path: file path for JSON
    - Throws: any errors that crop up from reading files or decoding te JSON, which would be a `DecodingError`.
    - Returns: nil if file could not be read or JSON can be parsed.
    - Note: Like the Matrix class implementation, this method is not to be used on remote files, due to how data is grabbed.
    */
    override public class func load(from path: URL) throws -> SuperMatrix<T, Element> {
        
        // create a decoder object
        let JSON_DECODER = JSONDecoder()
        
        // attempt to parse JSON from file
        let JSON_DATA = try Data(contentsOf: path)
        let DECODED_SUPER_MATRIX = try JSON_DECODER.decode(SuperMatrix<T, Element>.self, from: JSON_DATA)

        // return decoded SuperMatrix
        return DECODED_SUPER_MATRIX
    }
}

// extension that adds functionality only if the given type is itself a matrix
extension SuperMatrix where T == Matrix<Element> {
    
    /**
     grab rows from nested Matrix.
     - Parameters:
        - parameter r: child row.
        - parameter parent: row housing desired rows.
     - Precondition: parent must be a number between 0 and 1 less than the rows in matrix.
     - Returns: 2D array with elements in desired row.
     - Note: array will be empty if r is not within the confines of the child's total rows.
     */
    public func row(_ r: Int, in parent: Int) -> [[Element]] {
        
        // make sure parent row number is between 0 and ROW-1
        guard parent >= 0 && parent < ROWS else {
            preconditionFailure("parent row number must be between 0 and \(ROWS-1).")
        }
        
        return self[parent].map { matrix in
            
            // make sure row number is within valid range before attempting to retrieve row
            guard r >= 0 && r < matrix.ROWS else {
                return [Element]()
            }
            
            // return row
            return matrix[r]
        } // end closure
    } // end function
    
    /**
     grab elements from a particular column in the matrix.
     - Parameters:
        - parameter c: column index in children.
        - parameter parent: column index in parent.
     - Returns: 2D array containing numbers in the specified columns.
     - Note: While the method has no preconditions, this method uses a method that does (Refer to implementation in Matrix class).
     */
    public func column(_ c: Int, in parent: Int) -> [[Element]] {
        
        // create array to hold column data
        var column: [[Element]] = []
        
        // loop through each matrix in column
        for matrix in self[column: parent] {
            
            // append column data to array
            column.append(matrix[column: c])
        }
        
        // return column data
        return column
    }
} // end extension
