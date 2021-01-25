import Foundation

struct UserText {
    static let okAction = NSLocalizedString("action.ok", value: "OK", comment: "Ok action")
    static let cancelAction = NSLocalizedString("action.cancel", value: "Cancel", comment: "Cancel action")
    static let deleteAction = NSLocalizedString("action.delete", value: "Delete", comment: "Delete context action")
    static let favoriteAction = NSLocalizedString("action.favorite", value: "Favorite", comment: "Favorite context action")
    static let unfavoriteAction = NSLocalizedString("action.unfavorite", value: "Unfavorite", comment: "Unfavorite context action")

    static let authorizationDeniedMessage = NSLocalizedString("authorization.denied.message", value: "Frame Grabber works in unison with your photo library. Get started by allowing access in Settings.", comment: "Photo library authorization denied message")
    static let authorizationDeniedAction = NSLocalizedString("authorization.denied.action", value: "Open Settings", comment: "Photo library authorization denied action")
    static let authorizationUndeterminedMessage = NSLocalizedString("authorization.undetermined.message", value: "Frame Grabber works in unison with your photo library. Get started by allowing access to your videos and photos.", comment: "Photo library authorization default message")
    static let authorizationUndeterminedAction = NSLocalizedString("authorization.undetermined.action", value: "Get Started", comment: "Photo library authorization default action")

    static let aboutVersionFormat = NSLocalizedString("about.version.format", value: "Version %@", comment: "Version label with numerical version")
    static let aboutContactSubject = NSLocalizedString("about.email.subject", value: "Frame Grabber: Feedback", comment: "Feedback email subject")

    static let IAPAction = NSLocalizedString("iap.purchase.action", value: "Send Ice Cream", comment: "Purchase screen purchase button label")

    static let albumsUserAlbumsHeader = NSLocalizedString("albums.header.useralbum", value: "My Albums", comment: "User photo albums section header")

    static let albumDefaultTitle = NSLocalizedString("album.missing.title", value: "Album", comment: "Title for missing or deleted albums.")
    static let albumUnauthorizedTitle = NSLocalizedString("album.unauthorized.title", value: "Recents", comment: "Title for the initial placeholder album until the user authorizes.")
    static let albumLimitedAuthorizationTitle = NSLocalizedString("album.limited.title", value: "Library", comment: "Title for limited authorization in album view.")
    static let albumEmptyAny = NSLocalizedString("album.empty.any", value: "No Videos or Live Photos", comment: "Empty album message")
    static let albumEmptyVideos = NSLocalizedString("album.empty.video", value: "No Videos", comment: "No videos in album message")
    static let albumEmptyLive = NSLocalizedString("album.empty.livePhoto", value: "No Live Photos", comment: "No live photos in album message")
    static let albumViewSettingsMenuTitle = NSLocalizedString("album.viewSettings.menu.title", value: "View", comment: "Title of album view settings button menu")
    static let albumViewSettingsSquareGridTitle = NSLocalizedString("album.viewSettings.squareGrid.title", value: "Square Grid", comment: "Title of album view as squares settings menu item")
    static let albumViewSettingsFitGridTitle = NSLocalizedString("album.viewSettings.fitGrid.title", value: "Aspect Ratio Grid", comment: "Title of album view as aspect ratio settings menu item")
    
    static let limitedAuthorizationMenuTitle = NSLocalizedString("album.limited.menu.title", value: "You've given Frame Grabber access to a limited number of videos and Live Photos.", comment: "Title for limited authorization menu.")
    static let limitedAuthorizationMenuSelectPhotosAction = NSLocalizedString("album.limited.menu.selectphotos.action", value: "Select More Items", comment: "Action to select more photos in limited authorization menu.")
    static let limitedAuthorizationMenuOpenSettingsAction = NSLocalizedString("album.limited.menu.opensettings.action", value: "Change Settings", comment: "Action to open settings in limited authorization menu.")

    static let videoFilterAllItems = NSLocalizedString("videofilter.all", value: "All Items", comment: "Video filter title, all items")
    static let videoFilterVideos = NSLocalizedString("videofilter.video", value: "Videos", comment: "Video filter title, only videos")
    static let videoFilterLivePhotos = NSLocalizedString("videofilter.livePhoto", value: "Live Photos", comment: "Video filter title, only Live Photos")

    static let editorVideoLoadProgress = NSLocalizedString("progress.videoLoad.title", value: "Loading…", comment: "Video loading (iCloud or otherwise) progress title.")
    static let editorExportShareSheetProgress = NSLocalizedString("progress.export.shareSheet.title", value: "Exporting…", comment: "Frame generation progress title when showing the share sheet.")
    static let editorExportToPhotosProgress = NSLocalizedString("progress.export.saveToPhotos.title", value: "Saving to Photos…", comment: "Frame generation progress title when saving to Photos.")

    static let editorViewMetadataAction = NSLocalizedString("editor.more.metadata.action", value: "Metadata", comment: "Editor more button metadata button action")
    static let editorViewExportSettingsAction = NSLocalizedString("editor.more.exportSettings.action", value: "Export Settings", comment: "Editor more button export settings action")
    static let saveToPhotosAlbumName = "Frame Grabber"

    static let detailVideoTitle = NSLocalizedString("detail.video.title", value: "Video", comment: "Detail view title for videos")
    static let detailLivePhotoTitle = NSLocalizedString("detail.livephoto.title", value: "Live Photo", comment: "Detail view title for live photos")
    static let detailFrameDimensionsForVideoTitle = NSLocalizedString("detail.video.videodimensions.title", value: "Dimensions", comment: "Dimensions label title for videos")
    static let detailFrameDimensionsForLivePhotoTitle = NSLocalizedString("detail.livephoto.videodimensions.title", value: "Dimensions (Video)", comment: "Dimensions label title for the Live Photo video component")
    static let detailMapItem = NSLocalizedString("detail.map.item.title", value: "Location of Photo", comment: "Title of map item opened in Maps app.")

    static let exportImageFormatHeifSupportedFooter = NSLocalizedString("exportsettings.section.format.heifSupported.footer", value: "HEIF can result in smaller file sizes. JPEG is most widely supported.", comment: "Explanation of image formats in settings footer")
    static let exportImageFormatHeifNotSupportedFooter = NSLocalizedString("exportsettings.section.format.heifNotSupported.footer", value: "The HEIF format is not supported on this device.", comment: "Explanation of image formats in settings footer when HEIF is not supported")
    static let exportSettingsShowShareSheetFooter = NSLocalizedString("exportsettings.showShareSheet.footer", value: "Opens the share sheet for exporting.", comment: "Explanation of what the share sheet setting does")
    static let exportSettingsSaveToPhotosFooter = NSLocalizedString("exportsettings.saveToPhotos.footer", value: "Saves images to your photo library and adds them to the “Frame Grabber” photo album.", comment: "Explanation of what the save to photos setting does")
    static let exportShowShareSheetAction = NSLocalizedString("export.showShareSheet.action", value: "Share Sheet", comment: "Title for the share sheet export setting.")
    static let exportSaveToPhotosAction = NSLocalizedString("exportsettings.saveToPhotos.action", value: "Photo Library", comment: "Title for the save to photo library export setting.")
    static let exportSettingsFrameNumberFormatFooter = NSLocalizedString("exportsettings.frameNumber.footer", value: "Shows the frame number relative to the current seconds. For large videos, it might take a bit longer to determine the frame numbers.", comment: "Explanation of what the frame number time format does.")
    static let exportMillisecondsFormatTitle = NSLocalizedString("settings.milliseconds.title", value: "Milliseconds", comment: "Title for the milliseconds time format setting.")
    static let exportMillisecondsFormat = NSLocalizedString("settings.milliseconds.format", value: "mm:ss.SSS", comment: "The milliseconds format, used for display (but not for actual formatting).")
    static let exportFrameNumberFormatTitle = NSLocalizedString("settings.frameNumber.title", value: "Frames", comment: "Title for the frame number time format setting.")
    static let exportFrameNumberFormat = NSLocalizedString("settings.frameNumber.format", value: "mm:ss / ff", comment: "The frame number format, used for display (but not for actual formatting).")

    static let formatterFrameRateFormat = NSLocalizedString("formatter.framerate.format",  value: "%@ fps", comment: "Video frame rate with unit")
    static let formatterDimensionsFormat = NSLocalizedString("formatter.videodimensions.format", value: "%@ × %@ px", comment: "Video pixel size with unit")
    
    static let exifAppInformation = "Extracted with Frame Grabber \(Bundle.main.version)"  // Exif not localized
}

extension UserText {
    static let alertVideoLoadFailedTitle = NSLocalizedString("alert.videoload.title", value: "Unable to Load Item", comment: "")
    static let alertVideoLoadFailedMessage = NSLocalizedString("alert.videoload.message", value: "Please check your network settings and make sure the format is supported on this device.", comment: "")

    static let alertPlaybackFailedTitle = NSLocalizedString("alert.playback.title", value: "Cannot Play Item", comment: "")
    static let alertPlaybackFailedMessage = NSLocalizedString("alert.playback.message", value: "There was an error during playback.", comment: "")

    static let alertFrameExportFailedTitle = NSLocalizedString("alert.frameexport.title", value: "Unable to Export Image", comment: "")
    static let alertFrameExportFailedMessage = NSLocalizedString("alert.frameexport.message", value: "There was an error while generating the image.", comment: "")

    static let alertSavingToPhotosFailedTitle = NSLocalizedString("alert.saveToPhotos.title", value: "Unable to Save Image", comment: "")
    static let alertSavingToPhotosFailedMessage = NSLocalizedString("alert.saveToPhotos.message", value: "There was an error saving the image to Photos.", comment: "")
    
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
