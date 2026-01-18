import Foundation
import FirebaseFirestore
import Combine
import os.log

/// Protocol for capture session persistence operations
public protocol SessionServiceProtocol: Sendable {
    /// Create a new capture session document
    func createSession(
        userId: String,
        captureMode: CaptureMode,
        expectedImageCount: Int
    ) async throws -> String

    /// Update session with uploaded image URL
    func addUploadedImage(
        sessionId: String,
        imageUrl: String
    ) async throws

    /// Mark session as ready for detection
    func markReadyForDetection(sessionId: String) async throws

    /// Observe session updates (returns publisher)
    func observeSession(sessionId: String) -> AnyPublisher<CaptureSession?, Never>

    /// Fetch session by ID
    func getSession(sessionId: String) async throws -> CaptureSession?

    /// Delete a session
    func deleteSession(sessionId: String) async throws
}

/// Concrete implementation of SessionService for Firestore
public final class SessionService: SessionServiceProtocol {
    /// Firestore database reference.
    ///
    /// SAFETY: Marked `nonisolated(unsafe)` because:
    /// 1. Firestore is documented as thread-safe
    ///    (see Firebase offline persistence docs)
    /// 2. All Firestore operations are internally synchronized
    /// 3. We only perform read/write operations, never mutate the reference itself
    /// 4. This pattern is recommended by Firebase for Swift 6 compatibility
    ///
    /// If Firebase SDK changes threading guarantees in future versions,
    /// this should be wrapped in an actor.
    nonisolated(unsafe) private let db: Firestore
    private let logger = Logger(subsystem: "com.abundance.camerafeature", category: "SessionService")

    public init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    // MARK: - Create Session

    public func createSession(
        userId: String,
        captureMode: CaptureMode,
        expectedImageCount: Int
    ) async throws -> String {
        let sessionRef = db.collection("sessions").document()
        let sessionId = sessionRef.documentID

        let data: [String: Any] = [
            "id": sessionId,
            "userId": userId,
            "captureMode": captureMode.rawValue,
            "status": CaptureSessionStatus.uploading.rawValue,
            "createdAt": FieldValue.serverTimestamp(),
            "originalImageUrls": [],
            "imagesUploaded": 0,
            "expectedImageCount": expectedImageCount,
            "detectedObjects": []
        ]

        try await sessionRef.setData(data)
        logger.info("Created session \(sessionId) for user \(userId)")
        return sessionId
    }

    // MARK: - Update Session

    public func addUploadedImage(
        sessionId: String,
        imageUrl: String
    ) async throws {
        let sessionRef = db.collection("sessions").document(sessionId)

        try await sessionRef.updateData([
            "originalImageUrls": FieldValue.arrayUnion([imageUrl]),
            "imagesUploaded": FieldValue.increment(Int64(1))
        ])

        logger.debug("Added image to session \(sessionId)")
    }

    public func markReadyForDetection(sessionId: String) async throws {
        let sessionRef = db.collection("sessions").document(sessionId)

        try await sessionRef.updateData([
            "status": CaptureSessionStatus.detecting.rawValue
        ])

        logger.info("Session \(sessionId) marked ready for detection")
    }

    // MARK: - Observe Session

    public func observeSession(sessionId: String) -> AnyPublisher<CaptureSession?, Never> {
        let subject = PassthroughSubject<CaptureSession?, Never>()

        let listener = db.collection("sessions").document(sessionId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else {
                    subject.send(nil)
                    return
                }

                if let error {
                    self.logger.error("observeSession error: \(error.localizedDescription)")
                    subject.send(nil)
                    return
                }

                guard let data = snapshot?.data() else {
                    subject.send(nil)
                    return
                }

                do {
                    let session = try self.decodeSession(from: data, id: sessionId)
                    subject.send(session)
                } catch {
                    self.logger.error("Failed to decode session: \(error.localizedDescription)")
                    subject.send(nil)
                }
            }

        return subject
            .handleEvents(receiveCancel: {
                listener.remove()
            })
            .eraseToAnyPublisher()
    }

    // MARK: - Fetch Session

    public func getSession(sessionId: String) async throws -> CaptureSession? {
        let doc = try await db.collection("sessions").document(sessionId).getDocument()
        guard let data = doc.data() else { return nil }
        return try decodeSession(from: data, id: sessionId)
    }

    // MARK: - Delete Session

    public func deleteSession(sessionId: String) async throws {
        try await db.collection("sessions").document(sessionId).delete()
        logger.info("Deleted session \(sessionId)")
    }

    // MARK: - Private Helpers

    /// Decode detected objects using Codable for type safety and better error reporting
    private func decodeDetectedObjects(from data: [[String: Any]]) -> [ServerDetectedObject] {
        data.compactMap { objData in
            do {
                // Convert dictionary to JSON data for Codable decoding
                let jsonData = try JSONSerialization.data(withJSONObject: objData)
                let decoder = JSONDecoder()
                return try decoder.decode(ServerDetectedObject.self, from: jsonData)
            } catch {
                // Log the actual decoding error for debugging schema mismatches
                logger.error("Failed to decode ServerDetectedObject: \(error.localizedDescription)")
                return nil
            }
        }
    }

    private func decodeSession(from data: [String: Any], id: String) throws -> CaptureSession {
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let detectedAt = (data["detectedAt"] as? Timestamp)?.dateValue()

        let captureModeString = data["captureMode"] as? String ?? "single"
        let captureMode = CaptureMode(rawValue: captureModeString) ?? .single

        let statusString = data["status"] as? String ?? "uploading"
        let status = CaptureSessionStatus(rawValue: statusString) ?? .uploading

        let detectedObjects: [ServerDetectedObject]
        if let objectsArray = data["detectedObjects"] as? [[String: Any]] {
            detectedObjects = decodeDetectedObjects(from: objectsArray)
        } else {
            detectedObjects = []
        }

        return CaptureSession(
            id: id,
            userId: data["userId"] as? String ?? "",
            captureMode: captureMode,
            status: status,
            createdAt: createdAt,
            detectedAt: detectedAt,
            originalImageUrls: data["originalImageUrls"] as? [String] ?? [],
            imagesUploaded: data["imagesUploaded"] as? Int ?? 0,
            expectedImageCount: data["expectedImageCount"] as? Int ?? 1,
            detectedObjects: detectedObjects,
            reasoning: data["reasoning"] as? String,
            error: data["error"] as? String,
            errorCode: data["errorCode"] as? String
        )
    }
}
