import Foundation
import Models

/// Words for the shared components (cards, rows, bubbles, headers, pins). Components has no catalog of its own, so the
/// words live in Design's catalog under `component.<name>.<key>` (the same pattern as the badges in CP-5) and
/// Components shows them with `Text(verbatim:)`.
public enum ComponentStrings {
    // MARK: Place categories

    /// "Café", "Street food" … from Design's catalog (`category.<raw value>`); "Place" for a category this app
    /// version does not know.
    public static func categoryName(_ category: PlaceCategory) -> String {
        let fallback = String(localized: "category.unknown", bundle: #bundle)
        return Bundle.module.localizedString(forKey: "category.\(category.rawValue)", value: fallback, table: nil)
    }

    // MARK: Cards and rows

    /// "3 Spots" (plural rules in the catalog).
    public static func spotCount(_ count: Int) -> String {
        String(localized: "component.card.spots \(count)", bundle: #bundle)
    }

    public static func cardAccessibility(_ details: String) -> String {
        String(localized: "component.card.accessibility \(details)", bundle: #bundle)
    }

    /// "Spot 2 of 4".
    public static func spotPosition(_ order: Int, of total: Int) -> String {
        String(localized: "component.spot.position \(order) \(total)", bundle: #bundle)
    }

    public static var spotVisited: String { String(localized: "component.spot.visited", bundle: #bundle) }
    public static var spotCurrent: String { String(localized: "component.spot.current", bundle: #bundle) }
    public static var spotDuplicate: String { String(localized: "component.spot.duplicate", bundle: #bundle) }
    public static var spotReorder: String { String(localized: "component.spot.reorder", bundle: #bundle) }

    // MARK: Photos and avatars

    public static var photoUnavailable: String { String(localized: "component.photo.unavailable", bundle: #bundle) }

    public static func galleryPage(_ page: Int, of total: Int) -> String {
        String(localized: "component.gallery.page \(page) \(total)", bundle: #bundle)
    }

    public static func photoCredit(_ name: String) -> String {
        String(localized: "component.gallery.credit \(name)", bundle: #bundle)
    }

    public static func avatarLabel(_ name: String) -> String {
        String(localized: "component.avatar.photo \(name)", bundle: #bundle)
    }

    public static var avatarVerified: String { String(localized: "component.avatar.verified", bundle: #bundle) }

    public static func avatarMore(_ count: Int) -> String {
        String(localized: "component.avatar.more \(count)", bundle: #bundle)
    }

    // MARK: Post card

    /// "3 of 5 Spots".
    public static func visitedSpots(_ visited: Int, of total: Int) -> String {
        String(localized: "component.post.visited \(visited) \(total)", bundle: #bundle)
    }

    public static var like: String { String(localized: "component.post.like", bundle: #bundle) }
    public static var unlike: String { String(localized: "component.post.unlike", bundle: #bundle) }
    public static var comment: String { String(localized: "component.post.comment", bundle: #bundle) }
    public static var remix: String { String(localized: "component.post.remix", bundle: #bundle) }
    public static var share: String { String(localized: "component.post.share", bundle: #bundle) }
    public static var save: String { String(localized: "component.post.save", bundle: #bundle) }
    public static var unsave: String { String(localized: "component.post.unsave", bundle: #bundle) }
    public static var routeMap: String { String(localized: "component.post.routeMap", bundle: #bundle) }

    public static func likeCount(_ count: Int) -> String {
        String(localized: "component.post.likes \(count)", bundle: #bundle)
    }

    public static func commentCount(_ count: Int) -> String {
        String(localized: "component.post.comments \(count)", bundle: #bundle)
    }

    public static func remixCount(_ count: Int) -> String {
        String(localized: "component.post.remixes \(count)", bundle: #bundle)
    }

    // MARK: Comments

    public static var reply: String { String(localized: "component.comment.reply", bundle: #bundle) }
    public static var moreOptions: String { String(localized: "component.comment.more", bundle: #bundle) }
    public static var report: String { String(localized: "component.comment.report", bundle: #bundle) }
    public static var delete: String { String(localized: "component.comment.delete", bundle: #bundle) }
    public static var commentDeleted: String { String(localized: "component.comment.deleted", bundle: #bundle) }
    public static var moreReplies: String { String(localized: "component.comment.moreReplies", bundle: #bundle) }

    // MARK: Messages

    public static var messageDeleted: String { String(localized: "component.message.deleted", bundle: #bundle) }
    public static var messageEdited: String { String(localized: "component.message.edited", bundle: #bundle) }
    public static var receiptSent: String { String(localized: "component.message.sent", bundle: #bundle) }
    public static var receiptDelivered: String { String(localized: "component.message.delivered", bundle: #bundle) }
    public static var receiptSeen: String { String(localized: "component.message.seen", bundle: #bundle) }
    public static var you: String { String(localized: "component.message.you", bundle: #bundle) }
    public static var photo: String { String(localized: "component.message.photo", bundle: #bundle) }
    public static var playVoiceNote: String { String(localized: "component.message.play", bundle: #bundle) }
    public static var pauseVoiceNote: String { String(localized: "component.message.pause", bundle: #bundle) }

    public static func voiceNote(_ length: String) -> String {
        String(localized: "component.message.voice \(length)", bundle: #bundle)
    }

    public static var pollImIn: String { String(localized: "component.poll.imIn", bundle: #bundle) }
    public static var pollNotForMe: String { String(localized: "component.poll.notForMe", bundle: #bundle) }
    public static var pollYourVote: String { String(localized: "component.poll.yourVote", bundle: #bundle) }
    public static var pollTitle: String { String(localized: "component.poll.title", bundle: #bundle) }

    // MARK: Profile header

    public static var editProfile: String { String(localized: "component.profile.edit", bundle: #bundle) }
    public static var addFriend: String { String(localized: "component.profile.addFriend", bundle: #bundle) }
    public static var requested: String { String(localized: "component.profile.requested", bundle: #bundle) }
    public static var respond: String { String(localized: "component.profile.respond", bundle: #bundle) }
    public static var friends: String { String(localized: "component.profile.friends", bundle: #bundle) }
    public static var blocked: String { String(localized: "component.profile.blocked", bundle: #bundle) }
    public static var privateAccount: String { String(localized: "component.profile.private", bundle: #bundle) }
    public static var privateHint: String { String(localized: "component.profile.privateHint", bundle: #bundle) }
    public static var hangoutsDone: String { String(localized: "component.profile.hangoutsDone", bundle: #bundle) }
    public static var spotsVisited: String { String(localized: "component.profile.spotsVisited", bundle: #bundle) }
    public static var friendCount: String { String(localized: "component.profile.friendCount", bundle: #bundle) }

    // MARK: Map pins

    /// "3 Hangouts here, double tap to zoom".
    public static func clusterLabel(_ count: Int) -> String {
        String(localized: "component.pin.cluster \(count)", bundle: #bundle)
    }
}
