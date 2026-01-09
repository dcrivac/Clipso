//
//  ClipboardItemEntity+CoreDataProperties.swift
//  ClipboardManager
//
//  Created by crivac on 12/31/25.
//

import Foundation
import CoreData

extension ClipboardItemEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ClipboardItemEntity> {
        return NSFetchRequest<ClipboardItemEntity>(entityName: "ClipboardItemEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Date
    @NSManaged public var content: String?
    @NSManaged public var type: Int16
    @NSManaged public var category: Int16
    @NSManaged public var imageData: Data?
    @NSManaged public var encryptedContent: Data?
    @NSManaged public var isEncrypted: Bool
    @NSManaged public var sourceApp: String?
    @NSManaged public var ocrText: String?
    @NSManaged public var tags: String?
    @NSManaged public var isFavorite: Bool
    @NSManaged public var embedding: Data?
    @NSManaged public var projectTag: String?
    @NSManaged public var contextScore: Double
    @NSManaged public var relatedItemIDs: String?
    @NSManaged public var lastAccessedAt: Date?
    @NSManaged public var accessCount: Int16

}

extension ClipboardItemEntity: Identifiable {

}
