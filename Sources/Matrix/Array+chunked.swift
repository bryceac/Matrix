// extension to add functionality to array.
extension Array {
    /**
     split array into a 2D array.
     - parameter size: the size of the slices
     - Returns: a 2D array whose nested arrays are equal to a given size.
     */
    public func chunked(into size: Int) -> [[Element]] {
        
        // what through array by a specified number of steps and return results as a nested array
        return stride(from: 0, to: count, by: size).map {
            
            // return a slice as an array from closure
            Array(self[$0..<Swift.min($0+size, count)])
        }
    } // end function
} // end extension