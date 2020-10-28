import Foundation



/**
Position of a Matrix Element
*/
public struct MatrixIndex: Comparable, Hashable, Strideable {

    /// the number of rows in Matrix
    public static var maxRowNumber: Int!

    /// the number of columns in Matrix (this should be 1 less that the total number of columns, to work properly).
	public static var maxColumnNumber: Int!
	
    /**
    row index
    */
    public var row: Int
        
    /**
    column index
    */
    public var column: Int
        
    public static func ==(lhs: MatrixIndex, rhs: MatrixIndex) -> Bool {
        return lhs.row == rhs.row && lhs.column == rhs.column
    }
        
    public static func < (lhs: MatrixIndex, rhs: MatrixIndex) -> Bool {
        return lhs.row < rhs.row || lhs.column < rhs.column
    }

    /// advance the Index by a specified amount.
	public func advanced(by n: Int) -> MatrixIndex {
		var current = self
		
		switch n.signum() {
			case 1:
			
				for _ in 1...n {
					if current.column == MatrixIndex.maxColumnNumber {
						current.row += 1
						current.column = 0
					} else {
						current.column += 1
					}
				}
			case -1:
				for _ in 1...abs(n) {
					if current.row == MatrixIndex.maxRowNumber && current.column == 0 {
					current.column = MatrixIndex.maxColumnNumber
					current.row -= 1
					} else {
						current.column -= 1
					}
				}
			default: ()
		}
			
		return current
    }

    /// get the distance between the current index and a specified index.
	public func distance(to other: MatrixIndex) -> Int {
		var current = self
		var steps = 0
			
		if current < other {
			while current < other {
				current = advanced(by: 1)
					
				steps += 1
			}
		} else if current > other {
			while current > other {
				current = advanced(by: -1)
				steps += 1
			}
		}
			
		return steps
	}
 } // end struct