/// A a raycast query.
public struct RaycastQuery: IteratorProtocol, Sequence {

  /// The ray to cast, defined in the scene's coordinate space.
  public private(set) var ray: Ray

  /// The nodes with which ray collision should be tested.
  public private(set) var nodes: Node3D.NodeIterator

  /// Returns the elements of the sequence, sorted.
  public func sorted() -> [(node: Node3D, collisionDistance: Double)] {
    return sorted(by: { a, b in a.collisionDistance < b.collisionDistance })
  }

  public mutating func next() -> (node: Node3D, collisionDistance: Double)? {
    while let node = nodes.next() {
      if let distance = node.collisionShape?.collisionDistance(
        with: ray,
        translation: node.sceneTranslation,
        rotation: node.sceneRotation,
        scale: node.sceneScale,
        isCullingEnabled: false)
      {
        return (node: node, collisionDistance: distance)
      }
    }

    return nil
  }

}
