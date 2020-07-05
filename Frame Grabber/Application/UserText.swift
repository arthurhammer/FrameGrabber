import Foundation

struct UserText {
    static let okAction = NSLocalizedString("action.ok", value: "OK", comment: "Ok action")
    static let favoriteAction = NSLocalizedString("action.favorite", value: "Favorite", comment: "Favorite context action")
    static let unfavoriteAction = NSLocalizedString("action.unfavorite", value: "Unfavorite", comment: "Unfavorite context action")
    static let deleteAction = NSLocalizedString("action.delete", value: "Delete", comment: "Delete context action")

    static let authorizationTitle = NSLocalizedString("authorization.title", value: "Welcome to\nFrame Grabber", comment: "Photo library authorization title")
    static let authorizationDeniedMessage = NSLocalizedString("authorization.denied.message", value: "Save your favorite video and Live Photo moments as pictures. To get started, allow access to your photo library in Settings.", comment: "Photo library authorization denied message")
    static let authorizationDeniedAction = NSLocalizedString("authorization.denied.action", value: "Open Settings", comment: "Photo library authorization denied action")
    static let authorizationUndeterminedMessage = NSLocalizedString("authorization.undetermined.message", value: "Save your favorite video and Live Photo moments as pictures. Get started by allowing access to your photo library.", comment: "Photo library authorization default message")
    static let authorizationUndeterminedAction = NSLocalizedString("authorization.undetermined.action", value: "Get Started", comment: "Photo library authorization default action")

    static let aboutVersionFormat = NSLocalizedString("about.version.format", value: "Version %@", comment: "Version label with numerical version")
    static let aboutContactSubject = NSLocalizedString("about.email.subject", value: "Frame Grabber: Feedback", comment: "Feedback email subject")
    static let aboutPurchasedButton = NSLocalizedString("about.purchased.action", value: "Thank You", comment: "Container view button message when in-app purchase was purchased")
    static let aboutNotPurchasedButton = NSLocalizedString("about.notpurchased.action", value: "Ice Cream", comment: "Container view button message when in-app purchase was not purchased")

    static let IAPPurchasedTitle = NSLocalizedString("iap.purchased.title", value: "Thank You", comment: "Ice cream title label when purchased.")
    static let IAPPurchasedMessage = NSLocalizedString("iap.purchased.message", value: "Thank you so much for supporting me and my app!", comment: "Ice cream message label when purchased.")
    static let IAPNotPurchasedTitle = NSLocalizedString("iap.notpurchased.title", value: "Yummy", comment: "Ice cream title label when not purchased")
    static let IAPNotPurchasedMessage = NSLocalizedString("iap.notpurchased.message", value: "If you want to go the extra mile or support future development, you can send me this delicious piece of raspberry ice cream in form of a tip.\n\nAs a reward, you get the satisfaction of knowing you made my day. :)\n\nThank you for checking out my app!", comment: "Ice cream message label when not purchased")
    static let IAPActionWithPriceFormat = NSLocalizedString("iap.purchase.price.action.format", value: "Send Ice Cream – %@", comment: "Ice cream purchase button label with price")
    static let IAPActionWithoutPrice = NSLocalizedString("iap.purchase.noprice.action", value: "Send Ice Cream", comment: "Ice cream purchase button label without price")

    static let albumsUserAlbumsHeader = NSLocalizedString("albums.header.useralbum", value: "My Albums", comment: "User photo albums section header")

    static let albumUnauthorizedTitle = NSLocalizedString("album.unauthorized.title", value: "Recents", comment: "Title for the initial placeholder album until the user authorizes.")
    static let albumDefaultTitle = NSLocalizedString("album.missing.title", value: "Album", comment: "Title for missing or deleted albums.")
    static let albumEmptyAny = NSLocalizedString("album.empty.any", value: "No Videos or Live Photos", comment: "Empty album message")
    static let albumEmptyVideos = NSLocalizedString("album.empty.video", value: "No Videos", comment: "No videos in album message")
    static let albumEmptyLive = NSLocalizedString("album.empty.livePhoto", value: "No Live Photos", comment: "No live photos in album message")

    static let editorVideoLoadProgress = NSLocalizedString("progress.videoLoad.title", value: "Loading…", comment: "Video loading (iCloud or otherwise) progress title.")
    static let editorExportProgress = NSLocalizedString("progress.frameExport.title", value: "Exporting…", comment: "Frame generation progress title.")

    static let detailVideoTitle = NSLocalizedString("detail.video.title", value: "Video", comment: "Detail view title for videos")
    static let detailLivePhotoTitle = NSLocalizedString("detail.livephoto.title", value: "Live Photo", comment: "Detail view title for live photos")
    static let detailFrameDimensionsForVideoTitle = NSLocalizedString("detail.video.videodimensions.title", value: "Dimensions", comment: "Dimensions label title for videos")
    static let detailFrameDimensionsForLivePhotoTitle = NSLocalizedString("detail.livephoto.videodimensions.title", value: "Dimensions (Video)", comment: "Dimensions label title for the Live Photo video component")
    static let detailMapItem = NSLocalizedString("detail.map.item.title", value: "Your Shot", comment: "Title of map item opened in Maps app.")

    static let exportImageFormatSection = NSLocalizedString("exportoptions.section.format.title", value: "Image Format", comment: "Export settings image format section header")
    static let exportCompressionQualitySection = NSLocalizedString("exportoptions.section.compression.title", value: "Compression Quality", comment: "Export settings compression quality section header")

    static let formatterFrameRateFormat = NSLocalizedString("formatter.framerate.format",  value: "%@ fps", comment: "Video frame rate with unit")
    static let formatterDimensionsFormat = NSLocalizedString("formatter.videodimensions.format", value: "%@ × %@ px", comment: "Video pixel size with unit")
}

extension UserText {
    static let alertVideoLoadFailedTitle = NSLocalizedString("alert.videoload.title", value: "Unable to Load Item", comment: "")
    static let alertVideoLoadFailedMessage = NSLocalizedString("alert.videoload.message", value: "Please check your network settings and make sure the format is supported on this device.", comment: "")

    static let alertPlaybackFailedTitle = NSLocalizedString("alert.playback.title", value: "Cannot Play Item", comment: "")
    static let alertPlaybackFailedMessage = NSLocalizedString("alert.playback.message", value: "There was an error during playback.", comment: "")

    static let alertFrameExportFailedTitle = NSLocalizedString("alert.frameexport.title", value: "Unable to Export Image", comment: "")
    static let alertFrameExportFailedMessage = NSLocalizedString("alert.frameexport.message", value: "There was an error while generating the image.", comment: "")

    static let alertMailUnavailableTitle = NSLocalizedString("alert.mail.title", value: "This Device Can't Send Emails", comment: "")
    static let alertMailUnavailableMessageFormat = NSLocalizedString("alert.mail.message", value: "You can reach me at %@", comment: "E-mail address")

    static let alertIAPFailedTitle = NSLocalizedString("alert.iap.failed.title", value: "Cannot Purchase Ice Cream", comment: "Alert title: Purchasing failed.")
    static let alertIAPFailedMessage = NSLocalizedString("alert.iap.failed.message", value: "Please check your network settings and try again later. Thank you for your support!", comment: "Alert message: The purchase can't proceed because the product has not yet been fetched, usually due to network errors.")

    static let alertIAPUnauthorizedTitle = UserText.alertIAPFailedTitle
    static let alertIAPUnauthorizedMessage = NSLocalizedString("alert.iap.unauthorized.message", value: "In-App Purchases are not allowed on this device. Thank you for your support!", comment: "Alert message: The user is not authorized to make payments.")

    static let alertIAPUnavailableTitle = UserText.alertIAPFailedTitle
    static let alertIAPUnavailableMessage = UserText.alertIAPFailedMessage

    static let alertIAPRestoreFailedTitle = NSLocalizedString("alert.iap.restore.failed.title", value: "Cannot Restore Your Purchase", comment: "Alert title: Restoring failed.")
    static let alertIAPRestoreFailedMessage = UserText.alertIAPFailedMessage

    static let alertIAPRestoreUnauthorizedTitle = UserText.alertIAPRestoreFailedTitle
    static let alertIAPRestoreUnauthorizedMessage = UserText.alertIAPUnauthorizedMessage

    static let alertIAPRestoreEmptyTitle = NSLocalizedString("alert.iap.restore.empty.title", value: "Nothing to Restore", comment: "Alert title: Nothing to restore, the user has not previously purchased anything.")
    static let alertIAPRestoreEmptyMessage = NSLocalizedString("alert.iap.restore.empty.message", value: "Looks like you haven't sent any ice cream yet!", comment: "Alert message: Nothing to restore, the user has not previously purchased anything. ")
}
