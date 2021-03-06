import CGLFW

/// A collection of vertices, edges and faces that represents a 3D geometry.
public final class Mesh: GraphicsResource {

  /// Initializes a mesh from a mesh source.
  ///
  /// - Parameter source: The mesh's source.
  public init<Source>(source: Source) where Source: MeshSource {
    // Copy essential source data (i.e., those required by the drawing method).
    self.vertexCount = source.vertexCount
    self.vertexIndices = source.vertexIndices
    self.primitiveType = source.primitiveType
    self.aabb = source.aabb
    self.source = source
    self.state = .unloaded
  }

  /// The data source for this mesh.
  public var source: MeshSource?

  /// The number of vertices composing the mesh.
  public let vertexCount: Int

  /// The indices of each vertex in the vertex data, used for index drawing if defined.
  public let vertexIndices: [UInt32]?

  /// The drawing type that connect vertices when rendering the mesh.
  public let primitiveType: PrimitiveType

  /// A type of drawing primitive that connects vertices when rendering a mesh.
  public enum PrimitiveType {

    /// A sequence of triangles, each described by three new verticies.
    case triangles

    /// A sequence of lines, each described by two new vertices.
    case lines

    /// A sequence of unconnected points.
    case points

  }

  /// The mesh's axis-aligned bounding box.
  public private(set) var aabb: AxisAlignedBox

  /// Bakes the given transformation matrix into the mesh data.
  ///
  /// Usually, the translations, rotations and scaling of a model is controlled by the node to
  /// which it is attached, while the mesh data (e.g., vertex positions, normals, etc.) are left
  /// unchanged so that they can be stored into GPU memory. However, there might be situations
  /// where applying a transform directly on a mesh is preferrable. Common use cases include
  /// correcting the rotation/scaling of a mesh imported from a third-party modeling software, or
  /// mirroring a mesh along one axis.
  ///
  /// This method must be applied while __before__ the mesh is loaded into GPU memory, while its
  /// data source is still available (i.e., in the `unloaded` state). Attempting otherwise will
  /// result in a `StateError`.
  ///
  /// - Parameter transform: A matrix representing the transformations to bake.
  ///
  /// - Throws: `StateError` if the resource is not in the `unloaded` state.
  public func bake(transform: Matrix4) throws {
    guard state == .unloaded
      else { throw StateError(reason: "Baking transformations requires the mesh to be unloaded.") }

    source = MeshData(baking: transform, into: source!)
    aabb = source!.aabb
  }

  // MARK: Internal API

  /// The ID of OpenGL's vertex array.
  private var vaoID: GL.UInt = 0

  /// The ID of OpenGL's element array buffer.
  private var eboID: GL.UInt = 0

  /// The ID of OpenGL's vertex buffer.
  private var vboID: GL.UInt = 0

  /// Draws the model's meshes.
  ///
  /// This method should be called after the shader used to draw the mesh's vertices been bound.
  internal func draw() {
    assert(state == .loaded)

    // Bind the mesh's vertex array (VAO).
    glBindVertexArray(vaoID)

    // Draw the mesh's vertices.
    if let indices = vertexIndices {
      assert(eboID != 0)
      glDrawElements(
        primitiveType.glValue,
        GL.Size(indices.count),
        GL.Enum(GL_UNSIGNED_INT),
        nil)
    } else {
      glDrawArrays(primitiveType.glValue, 0, GL.Size(vertexCount))
    }

    // Unbind the mesh's buffer.
    glBindVertexArray(0)
  }

  internal var state: GraphicsResourceState

  internal func load() {
    assert(state != .gone)
    guard state != .loaded
      else { return }

    assert(AppContext.shared.isInitialized)
    assert(glfwGetCurrentContext() != nil)
    assert(source != nil)

    let drawHint = GL.DYNAMIC_DRAW

    // Upload the vertex data into a VAO and VBO.
    glGenVertexArrays(1, &vaoID)
    assert(vaoID != 0)
    glBindVertexArray(vaoID)

    glGenBuffers(1, &vboID)
    assert(vboID != 0)
    glBindBuffer(GL.ARRAY_BUFFER, vboID)

    source!.vertexData.withUnsafeBytes({ buffer in
      glBufferData(GL.ARRAY_BUFFER, buffer.count, buffer.baseAddress, drawHint)
    })

    for descriptor in source!.attributeDescriptors {
      let type = glTypeSymbol(of: descriptor.componentType)
      switch type {
      case GL.FLOAT:
        glVertexAttribPointer(
          GL.UInt(descriptor.shaderLocation),
          GL.Int(descriptor.componentCountPerVertex),
          GL.FLOAT,
          0,
          GL.Size(descriptor.stride),
          UnsafeRawPointer(bitPattern: descriptor.offset))

      case GL.DOUBLE:
        glVertexAttribLPointer(
          GL.UInt(descriptor.shaderLocation),
          GL.Int(descriptor.componentCountPerVertex),
          GL.DOUBLE,
          GL.Size(descriptor.stride),
          UnsafeRawPointer(bitPattern: descriptor.offset))

      case GL.INT, GL.UNSIGNED_INT:
        glVertexAttribIPointer(
          GL.UInt(descriptor.shaderLocation),
          GL.Int(descriptor.componentCountPerVertex),
          type!,
          GL.Size(descriptor.stride),
          UnsafeRawPointer(bitPattern: descriptor.offset))

      default:
        assertionFailure("Unsupported attribute type '\(descriptor.componentType)'")
      }

      glEnableVertexAttribArray(GL.UInt(descriptor.shaderLocation))
    }

    // Upload vertex indices into a EBO, if defined.
    if let indices = source!.vertexIndices {
      glGenBuffers(1, &eboID)
      assert(eboID != 0)
      glBindBuffer(GL.ELEMENT_ARRAY_BUFFER, eboID)
      indices.withUnsafeBufferPointer({ buffer in
        glBufferData(
          GL.ELEMENT_ARRAY_BUFFER,
          buffer.count * MemoryLayout<UInt32>.stride,
          buffer.baseAddress,
          drawHint)
      })
    }

    state = .loaded
  }

  internal func unload() {
    if vaoID > 0 {
      glDeleteBuffers(2, [vboID, eboID])
      glDeleteVertexArrays(1, &vaoID)

      vaoID = 0
      vboID = 0
      eboID = 0
    }

    state = source != nil
      ? .unloaded
      : .gone
  }

  deinit {
    // Delete the mesh's buffers from the GPU memory.
    glDeleteBuffers(2, [vboID, eboID])
    glDeleteVertexArrays(1, &vaoID)
  }

}
