import CFreeType

/// An object responsible for creating and managing font references.
public final class FontManager {

  public init?() {
    // Initializes the FreeType library object.
    guard FT_Init_FreeType(&library) == 0 else {
      LogManager.main.log("Failed to initialize FreeType.", level: .error)
      return nil
    }
  }

  /// Instantiates and returns a font face object from the contents of the specified file.
  public func face(
    fromContentsOfFile filename: String,
    size: Int = 48,
    index: Int = 0
  ) -> FontFace? {
    var face: FT_Face?
    guard FT_New_Face(library, filename, index, &face) == 0
      else { return nil }

    // Set the font's size.
    guard FT_Set_Pixel_Sizes(face, 0, FT_UInt(size)) == 0 else {
      LogManager.main.log("Failed to set the font size.", level: .warning)
      FT_Done_Face(face)
      return nil
    }

    return FontFace(face: face)
  }

  public func face(system: String, size: Int = 48) -> FontFace? {
    let fontName = "\(system).ttf"

#if os(macOS)
    guard let dir = opendir("/Library/Fonts/")
      else { return nil }

    while let entry = readdir(dir)?.pointee {
      let mirror = Mirror(reflecting: entry.d_name)
      let name = String(cString: mirror.children.map({ $0.value as! CChar }))
      if name == fontName {
        return face(fromContentsOfFile: "/Library/Fonts/\(name)", size: size)
      }
    }
#else
    LogManager.main.log("FontManager.face(system:size:) is not implemented", level: .debug)
#endif
    return nil
  }

  /// The handle of the FreeType library object.
  private var library: FT_Library?

  deinit {
    // Destroy the FreeType library object.
    FT_Done_FreeType(library)
  }
  
}
