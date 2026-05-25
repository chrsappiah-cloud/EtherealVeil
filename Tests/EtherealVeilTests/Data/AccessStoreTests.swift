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
        let user = try AccessStore.adminUser(in: context)
        XCTAssertEqual(user?.role, StudioUserRole.admin.rawValue)
        XCTAssertEqual(user?.email, "admin@worldclassscholars.com")
        XCTAssertNil(try AccessStore.currentUser(in: context))
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

    func testSignInRejectsReservedAdminAccount() throws {
        try AccessStore.ensureDefaultAdmin(in: context)
        XCTAssertThrowsError(
            try AccessStore.signIn(
                email: "admin@worldclassscholars.com",
                displayName: "Admin",
                in: context
            )
        ) { error in
            XCTAssertEqual(error as? AccessStoreError, .reservedAccount)
        }
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
            update: .init(
                tier: .pro,
                status: .adminGranted,
                isActive: true,
                expiresAt: .now.addingTimeInterval(86400 * 30),
                note: "Investor demo"
            ),
            in: context
        )
        XCTAssertEqual(member.accessTier, StudioAccessTier.pro.rawValue)
        XCTAssertEqual(try AccessStore.auditLogs(in: context).count, 1)
    }

    func testSignInReusesExistingUser() throws {
        try AccessStore.ensureDefaultAdmin(in: context)
        let first = try AccessStore.signIn(
            email: "artist@example.com",
            displayName: "Artist",
            in: context
        )
        let second = try AccessStore.signIn(
            email: "artist@example.com",
            displayName: "Updated Name",
            in: context
        )
        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(second.displayName, "Updated Name")
    }

    func testActivateReviewModeCreatesFullAccessDemoUser() throws {
        let user = try AccessStore.activateReviewMode(in: context)
        XCTAssertEqual(user.email, AccessStore.reviewDemoEmail)
        XCTAssertEqual(user.accessTier, StudioAccessTier.enterprise.rawValue)
        XCTAssertEqual(user.subscriptionStatus, StudioSubscriptionStatus.trial.rawValue)
        XCTAssertEqual(try AccessStore.currentUser(in: context)?.email, AccessStore.reviewDemoEmail)
    }
}
