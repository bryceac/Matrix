public struct MatrixIterator<T>: IteratorProtocol {
	public var rowIndex: Int = 0
	public var columnIndex: Int = 0
	
	private let MATRIX: Matrix<T>
	
	public init(withMatrix matrix: Matrix<T>) {
		MATRIX = matrix
	}
	
	public mutating func next() -> T? {
		guard rowIndex < MATRIX.ROWS else { return nil }
	
		let MODEL = MATRIX[rowIndex, columnIndex]
		
		if columnIndex < MATRIX.COLUMNS-1 {
			columnIndex += 1
		} else {
			rowIndex += 1
			columnIndex = 0
		}
		
		return MODEL
	}
	
}
