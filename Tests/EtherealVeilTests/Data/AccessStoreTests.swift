// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson

import XCTest
import SwiftData
@testable import EtherealVeil

@MainActor
final class AccessStoreTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUp() async throws {
        container = PersistenceController(inMemory: true).container
        context = container.mainContext
    }

    override func tearDown() async throws {
        context = nil
        container = nil
    }

    func testEnsureDefaultAdminCreatesAdmin() throws {
        try AccessStore.ensureDefaultAdmin(in: context)
        let user = try AccessStore.currentUser(in: context)
        XCTAssertEqual(user?.role, StudioUserRole.admin.rawValue)
        XCTAssertEqual(user?.email, "admin@worldclassscholars.com")
    }

    func testSignInCreatesUser() throws {
        try AccessStore.ensureDefaultAdmin(in: context)
        let user = try AccessStore.signIn(
            email: "artist@example.com",
            displayName: "Artist",
            in: context
        )
        XCTAssertEqual(user.email, "artist@example.com")
        XCTAssertEqual(user.accessTier, StudioAccessTier.free.rawValue)
    }

    func testAdminCanGrantPro() throws {
        try AccessStore.ensureDefaultAdmin(in: context)
        let admin = try XCTUnwrap(try AccessStore.adminUser(in: context))
        let member = try AccessStore.signIn(
            email: "member@example.com",
            displayName: "Member",
            in: context
        )
        try AccessStore.adminUpdateUser(
            actor: admin,
            target: member,
            tier: .pro,
            status: .adminGranted,
            isActive: true,
            expiresAt: .now.addingTimeInterval(86400 * 30),
            note: "Investor demo",
            in: context
        )
        XCTAssertEqual(member.accessTier, StudioAccessTier.pro.rawValue)
        XCTAssertEqual(try AccessStore.auditLogs(in: context).count, 1)
    }
}
