import CGLFW

// MARK: Types and constants

/// A namespace for type aliases various OpenGL constants.
internal enum GL {

  // MARK: Type aliases

  typealias Bool      = Swift.Int32
  typealias BitField  = Swift.UInt32
  typealias Int       = Swift.Int32
  typealias UInt      = Swift.UInt32
  typealias Enum      = Swift.UInt32
  typealias Size      = Swift.Int32

  // MARK: Constants

  static var COLOR_BUFFER_BIT         : BitField { BitField(GL_COLOR_BUFFER_BIT) }
  static var DEPTH_BUFFER_BIT         : BitField { BitField(GL_DEPTH_BUFFER_BIT) }
  static var SCISSOR_TEST             : BitField { BitField(GL_SCISSOR_TEST) }
  static var STENCIL_BUFFER_BIT       : BitField { BitField(GL_STENCIL_BUFFER_BIT) }

  static var FALSE                    : Bool { Bool(GL_FALSE) }
  static var TRUE                     : Bool { Bool(GL_TRUE) }

  static var ALWAYS                   : Enum { Enum(GL_ALWAYS) }
  static var ARRAY_BUFFER             : Enum { Enum(GL_ARRAY_BUFFER) }
  static var BACK                     : Enum { Enum(GL_BACK) }
  static var BLEND                    : Enum { Enum(GL_BLEND) }
  static var BYTE                     : Enum { Enum(GL_BYTE) }
  static var CLAMP_TO_BORDER          : Enum { Enum(GL_CLAMP_TO_BORDER) }
  static var CLAMP_TO_EDGE            : Enum { Enum(GL_CLAMP_TO_EDGE) }
  static var COLOR_ATTACHMENT0        : Enum { Enum(GL_COLOR_ATTACHMENT0) }
  static var COMPILE_STATUS           : Enum { Enum(GL_COMPILE_STATUS) }
  static var CULL_FACE                : Enum { Enum(GL_CULL_FACE) }
  static var DECR                     : Enum { Enum(GL_DECR) }
  static var DECR_WRAP                : Enum { Enum(GL_DECR_WRAP) }
  static var DEPTH_ATTACHMENT         : Enum { Enum(GL_DEPTH_ATTACHMENT) }
  static var DEPTH_COMPONENT          : Enum { Enum(GL_DEPTH_COMPONENT) }
  static var DEPTH_COMPONENT32F       : Enum { Enum(GL_DEPTH_COMPONENT32F) }
  static var DEPTH_STENCIL_ATTACHMENT : Enum { Enum(GL_DEPTH_STENCIL_ATTACHMENT) }
  static var DEPTH_TEST               : Enum { Enum(GL_DEPTH_TEST) }
  static var DEPTH24_STENCIL8         : Enum { Enum(GL_DEPTH24_STENCIL8) }
  static var DEPTH_STENCIL            : Enum { Enum(GL_DEPTH_STENCIL) }
  static var DOUBLE                   : Enum { Enum(GL_DOUBLE) }
  static var DYNAMIC_DRAW             : Enum { Enum(GL_DYNAMIC_DRAW) }
  static var ELEMENT_ARRAY_BUFFER     : Enum { Enum(GL_ELEMENT_ARRAY_BUFFER) }
  static var EQUAL                    : Enum { Enum(GL_EQUAL) }
  static var FILL                     : Enum { Enum(GL_FILL) }
  static var FLOAT                    : Enum { Enum(GL_FLOAT) }
  static var FRAMEBUFFER              : Enum { Enum(GL_FRAMEBUFFER) }
  static var FRAMEBUFFER_COMPLETE     : Enum { Enum(GL_FRAMEBUFFER_COMPLETE) }
  static var FRAMEBUFFER_SRGB         : Enum { Enum(GL_FRAMEBUFFER_SRGB) }
  static var FRAMEBUFFER_UNSUPPORTED  : Enum { Enum(GL_FRAMEBUFFER_UNSUPPORTED) }
  static var FRONT                    : Enum { Enum(GL_FRONT) }
  static var FRONT_AND_BACK           : Enum { Enum(GL_FRONT_AND_BACK) }
  static var FRAGMENT_SHADER          : Enum { Enum(GL_FRAGMENT_SHADER) }
  static var GEQUAL                   : Enum { Enum(GL_GEQUAL) }
  static var GREATER                  : Enum { Enum(GL_GREATER) }
  static var INCR                     : Enum { Enum(GL_INCR) }
  static var INCR_WRAP                : Enum { Enum(GL_INCR_WRAP) }
  static var INFO_LOG_LENGTH          : Enum { Enum(GL_INFO_LOG_LENGTH) }
  static var INT                      : Enum { Enum(GL_INT) }
  static var INVERT                   : Enum { Enum(GL_INVERT) }
  static var KEEP                     : Enum { Enum(GL_KEEP) }
  static var LEQUAL                   : Enum { Enum(GL_LEQUAL) }
  static var LESS                     : Enum { Enum(GL_LESS) }
  static var LINEAR                   : Enum { Enum(GL_LINEAR) }
  static var LINE                     : Enum { Enum(GL_LINE) }
  static var LINES                    : Enum { Enum(GL_LINES) }
  static var LINK_STATUS              : Enum { Enum(GL_LINK_STATUS) }
  static var MAX_COLOR_ATTACHMENTS    : Enum { Enum(GL_MAX_COLOR_ATTACHMENTS) }
  static var MIRRORED_REPEAT          : Enum { Enum(GL_MIRRORED_REPEAT) }
  static var NEAREST                  : Enum { Enum(GL_NEAREST) }
  static var NEVER                    : Enum { Enum(GL_NEVER) }
  static var NO_ERROR                 : Enum { Enum(GL_NO_ERROR) }
  static var NONE                     : Enum { Enum(GL_NONE) }
  static var NOTEQUAL                 : Enum { Enum(GL_NOTEQUAL) }
  static var ONE                      : Enum { Enum(GL_ONE) }
  static var ONE_MINUS_SRC_ALPHA      : Enum { Enum(GL_ONE_MINUS_SRC_ALPHA) }
  static var POINT                    : Enum { Enum(GL_POINT) }
  static var POINTS                   : Enum { Enum(GL_POINTS) }
  static var RED                      : Enum { Enum(GL_RED) }
  static var REPEAT                   : Enum { Enum(GL_REPEAT) }
  static var REPLACE                  : Enum { Enum(GL_REPLACE) }
  static var RENDERBUFFER             : Enum { Enum(GL_RENDERBUFFER) }
  static var RGB                      : Enum { Enum(GL_RGB) }
  static var RGBA                     : Enum { Enum(GL_RGBA) }
  static var SHORT                    : Enum { Enum(GL_SHORT) }
  static var SRC_ALPHA                : Enum { Enum(GL_SRC_ALPHA) }
  static var SRGB_ALPHA               : Enum { Enum(GL_SRGB_ALPHA) }
  static var STENCIL_ATTACHMENT       : Enum { Enum(GL_STENCIL_ATTACHMENT) }
  static var STENCIL_TEST             : Enum { Enum(GL_STENCIL_TEST) }
  static var TEXTURE_2D               : Enum { Enum(GL_TEXTURE_2D) }
  static var TEXTURE_HEIGHT           : Enum { Enum(GL_TEXTURE_HEIGHT) }
  static var TEXTURE_MAG_FILTER       : Enum { Enum(GL_TEXTURE_MAG_FILTER) }
  static var TEXTURE_MIN_FILTER       : Enum { Enum(GL_TEXTURE_MIN_FILTER) }
  static var TEXTURE_WIDTH            : Enum { Enum(GL_TEXTURE_WIDTH) }
  static var TEXTURE_WRAP_S           : Enum { Enum(GL_TEXTURE_WRAP_S) }
  static var TEXTURE_WRAP_T           : Enum { Enum(GL_TEXTURE_WRAP_T) }
  static var TEXTURE0                 : Enum { Enum(GL_TEXTURE0) }
  static var TRIANGLES                : Enum { Enum(GL_TRIANGLES) }
  static var UNPACK_ALIGNMENT         : Enum { Enum(GL_UNPACK_ALIGNMENT) }
  static var UNSIGNED_BYTE            : Enum { Enum(GL_UNSIGNED_BYTE) }
  static var UNSIGNED_INT             : Enum { Enum(GL_UNSIGNED_INT) }
  static var UNSIGNED_INT_24_8        : Enum { Enum(GL_UNSIGNED_INT_24_8) }
  static var UNSIGNED_SHORT           : Enum { Enum(GL_UNSIGNED_SHORT) }
  static var VERTEX_SHADER            : Enum { Enum(GL_VERTEX_SHADER) }
  static var ZERO                     : Enum { Enum(GL_ZERO) }

}

// MARK: Function convenience overloads

/// Convenience wrapper around `glEnable` and `glDisable`.
internal func glToggle(capability: GL.Enum, isEnabled: Bool) {
  if isEnabled {
    glEnable(capability)
  } else {
    glDisable(capability)
  }
}

/// Convenience wrapper around `glClearColor`.
internal func glClearColor(_ color: Color) {
  glClearColor(
    Float(color.red),
    Float(color.green),
    Float(color.blue),
    Float(color.alpha))
}

/// Convenience overload of `glScissor`.
internal func glScissor(region: Rectangle) {
  glScissor(GL.Int(region.minX), GL.Int(region.minY), GL.Int(region.width), GL.Int(region.height))
}

/// Convenience overload of `glViewport`.
internal func glViewport(region: Rectangle) {
  glViewport(GL.Int(region.minX), GL.Int(region.minY), GL.Int(region.width), GL.Int(region.height))
}

// MARK: Converters

extension Image.PixelFormat {

  internal var glValue: GL.Enum {
    switch self {
    case .gray              : return GL.RED
    case .rgba              : return GL.RGBA
    }
  }

}

extension Mesh.PrimitiveType {

  internal var glValue: GL.Enum {
    switch self {
    case .triangles         : return GL.TRIANGLES
    case .lines             : return GL.LINES
    case .points            : return GL.POINTS
    }
  }

}

extension Texture.InternalFormat {

  internal var glValue: GL.Enum {
    switch self {
    case .red               : return GL.RED
    case .rgba              : return GL.RGBA
    case .srgba             : return GL.SRGB_ALPHA
    case .depth32F          : return GL.DEPTH_COMPONENT32F
    case .depth24Stencil8   : return GL.DEPTH24_STENCIL8
    }
  }

  internal var glTransferFormat: (format: GL.Enum, type: GL.Enum) {
    switch self {
    case .red               : return (GL.RED            , GL.UNSIGNED_BYTE)
    case .rgba              : return (GL.RGBA           , GL.UNSIGNED_BYTE)
    case .srgba             : return (GL.RGBA           , GL.UNSIGNED_BYTE)
    case .depth32F          : return (GL.DEPTH_COMPONENT, GL.FLOAT)
    case .depth24Stencil8   : return (GL.DEPTH_STENCIL  , GL.UNSIGNED_INT_24_8)
    }
  }

}

extension Texture.WrapMethod {

  internal init?(glValue: GL.Enum) {
    switch glValue {
    case GL.CLAMP_TO_BORDER : self = .clampedToBorder
    case GL.CLAMP_TO_EDGE   : self = .clampedToEdge
    case GL.MIRRORED_REPEAT : self = .mirroredRepeat
    case GL.REPEAT          : self = .repeat
    default                 : return nil
    }
  }

  internal var glValue: GL.Enum {
    switch self {
    case .clampedToBorder   : return GL.CLAMP_TO_BORDER
    case .clampedToEdge     : return GL.CLAMP_TO_EDGE
    case .mirroredRepeat    : return GL.MIRRORED_REPEAT
    case .repeat            : return GL.REPEAT
    }
  }

}

internal func glTypeSymbol(of type: Any.Type) -> GL.Enum? {
  if type == Int8.self   { return GL.Enum(GL_BYTE) }
  if type == UInt8.self  { return GL.Enum(GL_UNSIGNED_BYTE) }
  if type == Int16.self  { return GL.Enum(GL_SHORT) }
  if type == UInt16.self { return GL.Enum(GL_UNSIGNED_SHORT) }
  if type == Int32.self  { return GL.Enum(GL_INT) }
  if type == UInt32.self { return GL.Enum(GL_UNSIGNED_INT) }
  if type == Float.self  { return GL.Enum(GL_FLOAT) }
  if type == Double.self { return GL.Enum(GL_DOUBLE) }

  return nil
}

// MARK: Helpers

internal func glWarnError() {
  let error = glGetError()
  if error != GL.NO_ERROR {
    LogManager.main.log("OpenGL Error '\(error)'", level: .warning)
  }
}
