public struct Color {
	public let red: UInt8
	public let green: UInt8
	public let blue: UInt8
	public let alpha: UInt8
	
	public var rgb: UInt32 { return UInt32((red << 16) | (green << 8) | blue) }
	public var rgba: UInt32 { return UInt32((red << 24) | (green << 16) | (blue << 8) | alpha) }
	public var argb: UInt32 { return UInt32((alpha << 24) | (red << 16) | (green << 8) | blue) }
	
	public init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8 = 255) {
		self.red = red
		self.green = green
		self.blue = blue
		self.alpha = alpha
	}
	
	public func alphaBlend(over bottomLayer: Color) -> Color {
		let floatAlpha = Double(alpha) / 255.0
		let invAlpha = 1.0 - floatAlpha
		return Color(
			red: UInt8((Double(red) * floatAlpha) + (Double(bottomLayer.red) * invAlpha)),
			green: UInt8((Double(green) * floatAlpha) + (Double(bottomLayer.green) * invAlpha)),
			blue: UInt8((Double(blue) * floatAlpha) + Double(bottomLayer.blue) * invAlpha
)		)
	}
}
