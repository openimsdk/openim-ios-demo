
import Foundation

public enum CacheError: Error {

    case notFound

    case invalidData

    case custom(Error)

}

public protocol KeyValueCaching {

    associatedtype CachingKey

    associatedtype Entity

    func isEntityCached(for key: CachingKey) -> Bool

    func getEntity(for key: CachingKey) throws -> Entity

    func store(entity: Entity, for key: CachingKey) throws

}

public protocol AsyncKeyValueCaching: KeyValueCaching {

    associatedtype CachingKey

    associatedtype Entity

    func getEntity(for key: CachingKey, completion: @escaping (Result<Entity, Error>) -> Void)

}

public extension AsyncKeyValueCaching {

    func getEntity(for key: CachingKey, completion: @escaping (Result<Entity, Error>) -> Void) {
        DispatchQueue.global().async {
            do {
                let entity = try self.getEntity(for: key)
                DispatchQueue.main.async {
                    completion(.success(entity))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

}
