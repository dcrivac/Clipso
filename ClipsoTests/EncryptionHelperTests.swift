import XCTest
@testable import Clipso

final class EncryptionHelperTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Clean up any existing test keys
        EncryptionHelper.deleteKey()
    }

    override func tearDown() {
        // Clean up after tests
        EncryptionHelper.deleteKey()
        super.tearDown()
    }

    // MARK: - Encryption/Decryption Tests

    func testEncryptionDecryption() {
        let originalText = "Hello, World! This is a test."

        // Encrypt
        guard let encryptedData = EncryptionHelper.encrypt(originalText) else {
            XCTFail("Encryption failed")
            return
        }

        // Verify encrypted data is not empty
        XCTAssertFalse(encryptedData.isEmpty, "Encrypted data should not be empty")

        // Decrypt
        guard let decryptedText = EncryptionHelper.decrypt(encryptedData) else {
            XCTFail("Decryption failed")
            return
        }

        // Verify decrypted text matches original
        XCTAssertEqual(decryptedText, originalText, "Decrypted text should match original")
    }

    func testEncryptEmptyString() {
        let emptyText = ""

        guard let encryptedData = EncryptionHelper.encrypt(emptyText) else {
            XCTFail("Encryption of empty string failed")
            return
        }

        guard let decryptedText = EncryptionHelper.decrypt(encryptedData) else {
            XCTFail("Decryption of empty string failed")
            return
        }

        XCTAssertEqual(decryptedText, emptyText, "Encrypted empty string should decrypt to empty string")
    }

    func testEncryptLargeText() {
        // Test with a large string (10KB)
        let largeText = String(repeating: "Lorem ipsum dolor sit amet. ", count: 1000)

        guard let encryptedData = EncryptionHelper.encrypt(largeText) else {
            XCTFail("Encryption of large text failed")
            return
        }

        guard let decryptedText = EncryptionHelper.decrypt(encryptedData) else {
            XCTFail("Decryption of large text failed")
            return
        }

        XCTAssertEqual(decryptedText, largeText, "Large text should encrypt and decrypt correctly")
    }

    func testEncryptUnicodeText() {
        let unicodeText = "Hello 👋 世界 🌍 Привет مرحبا"

        guard let encryptedData = EncryptionHelper.encrypt(unicodeText) else {
            XCTFail("Encryption of unicode text failed")
            return
        }

        guard let decryptedText = EncryptionHelper.decrypt(encryptedData) else {
            XCTFail("Decryption of unicode text failed")
            return
        }

        XCTAssertEqual(decryptedText, unicodeText, "Unicode text should encrypt and decrypt correctly")
    }

    func testEncryptSpecialCharacters() {
        let specialChars = "!@#$%^&*()_+-=[]{}|;:',.<>?/~`\"\\"

        guard let encryptedData = EncryptionHelper.encrypt(specialChars) else {
            XCTFail("Encryption of special characters failed")
            return
        }

        guard let decryptedText = EncryptionHelper.decrypt(encryptedData) else {
            XCTFail("Decryption of special characters failed")
            return
        }

        XCTAssertEqual(decryptedText, specialChars, "Special characters should encrypt and decrypt correctly")
    }

    // MARK: - Key Persistence Tests

    func testKeyPersistence() {
        let text1 = "First encryption"
        let text2 = "Second encryption"

        // First encryption creates key
        guard let encrypted1 = EncryptionHelper.encrypt(text1) else {
            XCTFail("First encryption failed")
            return
        }

        // Second encryption should use same key
        guard let encrypted2 = EncryptionHelper.encrypt(text2) else {
            XCTFail("Second encryption failed")
            return
        }

        // Both should decrypt correctly
        XCTAssertEqual(EncryptionHelper.decrypt(encrypted1), text1)
        XCTAssertEqual(EncryptionHelper.decrypt(encrypted2), text2)
    }

    func testMultipleEncryptionsSameInput() {
        let text = "Test message"

        // Encrypt same text twice
        guard let encrypted1 = EncryptionHelper.encrypt(text) else {
            XCTFail("First encryption failed")
            return
        }

        guard let encrypted2 = EncryptionHelper.encrypt(text) else {
            XCTFail("Second encryption failed")
            return
        }

        // Encrypted data should be different (due to random nonce)
        XCTAssertNotEqual(encrypted1, encrypted2, "Two encryptions of same text should produce different ciphertext")

        // But both should decrypt to same original text
        XCTAssertEqual(EncryptionHelper.decrypt(encrypted1), text)
        XCTAssertEqual(EncryptionHelper.decrypt(encrypted2), text)
    }

    // MARK: - Error Handling Tests

    func testDecryptInvalidData() {
        let invalidData = Data([0x00, 0x01, 0x02, 0x03])

        let decrypted = EncryptionHelper.decrypt(invalidData)
        XCTAssertNil(decrypted, "Decrypting invalid data should return nil")
    }

    func testDecryptEmptyData() {
        let emptyData = Data()

        let decrypted = EncryptionHelper.decrypt(emptyData)
        XCTAssertNil(decrypted, "Decrypting empty data should return nil")
    }

    func testDecryptTruncatedData() {
        let originalText = "Test message for truncation"

        guard let encryptedData = EncryptionHelper.encrypt(originalText) else {
            XCTFail("Encryption failed")
            return
        }

        // Truncate encrypted data
        let truncatedData = encryptedData.prefix(encryptedData.count / 2)

        let decrypted = EncryptionHelper.decrypt(truncatedData)
        XCTAssertNil(decrypted, "Decrypting truncated data should return nil")
    }
}
