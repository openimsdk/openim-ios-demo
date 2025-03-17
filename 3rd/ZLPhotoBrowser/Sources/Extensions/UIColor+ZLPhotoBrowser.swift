

























import UIKit

extension ZLPhotoBrowserWrapper where Base: UIColor {
    static var navBarColor: UIColor {
        ZLPhotoUIConfiguration.default().navBarColor
    }
    
    static var navBarColorOfPreviewVC: UIColor {
        ZLPhotoUIConfiguration.default().navBarColorOfPreviewVC
    }

    static var navTitleColor: UIColor {
        ZLPhotoUIConfiguration.default().navTitleColor
    }

    static var navTitleColorOfPreviewVC: UIColor {
        ZLPhotoUIConfiguration.default().navTitleColorOfPreviewVC
    }

    static var navEmbedTitleViewBgColor: UIColor {
        ZLPhotoUIConfiguration.default().navEmbedTitleViewBgColor
    }

    static var previewBgColor: UIColor {
        ZLPhotoUIConfiguration.default().sheetTranslucentColor
    }

    static var previewBtnBgColor: UIColor {
        ZLPhotoUIConfiguration.default().sheetBtnBgColor
    }

    static var previewBtnTitleColor: UIColor {
        ZLPhotoUIConfiguration.default().sheetBtnTitleColor
    }

    static var previewBtnHighlightTitleColor: UIColor {
        ZLPhotoUIConfiguration.default().sheetBtnTitleTintColor
    }

    static var albumListBgColor: UIColor {
        ZLPhotoUIConfiguration.default().albumListBgColor
    }

    static var embedAlbumListTranslucentColor: UIColor {
        ZLPhotoUIConfiguration.default().embedAlbumListTranslucentColor
    }

    static var albumListTitleColor: UIColor {
        ZLPhotoUIConfiguration.default().albumListTitleColor
    }

    static var albumListCountColor: UIColor {
        ZLPhotoUIConfiguration.default().albumListCountColor
    }

    static var separatorLineColor: UIColor {
        ZLPhotoUIConfiguration.default().separatorColor
    }

    static var thumbnailBgColor: UIColor {
        ZLPhotoUIConfiguration.default().thumbnailBgColor
    }

    static var previewVCBgColor: UIColor {
        ZLPhotoUIConfiguration.default().previewVCBgColor
    }

    static var bottomToolViewBgColor: UIColor {
        ZLPhotoUIConfiguration.default().bottomToolViewBgColor
    }

    static var bottomToolViewBgColorOfPreviewVC: UIColor {
        ZLPhotoUIConfiguration.default().bottomToolViewBgColorOfPreviewVC
    }

    static var originalSizeLabelTextColor: UIColor {
        ZLPhotoUIConfiguration.default().originalSizeLabelTextColor
    }

    static var originalSizeLabelTextColorOfPreviewVC: UIColor {
        ZLPhotoUIConfiguration.default().originalSizeLabelTextColorOfPreviewVC
    }

    static var bottomToolViewBtnNormalTitleColor: UIColor {
        ZLPhotoUIConfiguration.default().bottomToolViewBtnNormalTitleColor
    }

    static var bottomToolViewDoneBtnNormalTitleColor: UIColor {
        ZLPhotoUIConfiguration.default().bottomToolViewDoneBtnNormalTitleColor
    }

    static var bottomToolViewBtnNormalTitleColorOfPreviewVC: UIColor {
        ZLPhotoUIConfiguration.default().bottomToolViewBtnNormalTitleColorOfPreviewVC
    }

    static var bottomToolViewDoneBtnNormalTitleColorOfPreviewVC: UIColor {
        ZLPhotoUIConfiguration.default().bottomToolViewDoneBtnNormalTitleColorOfPreviewVC
    }

    static var bottomToolViewBtnDisableTitleColor: UIColor {
        ZLPhotoUIConfiguration.default().bottomToolViewBtnDisableTitleColor
    }

    static var bottomToolViewDoneBtnDisableTitleColor: UIColor {
        ZLPhotoUIConfiguration.default().bottomToolViewDoneBtnDisableTitleColor
    }

    static var bottomToolViewBtnDisableTitleColorOfPreviewVC: UIColor {
        ZLPhotoUIConfiguration.default().bottomToolViewBtnDisableTitleColorOfPreviewVC
    }

    static var bottomToolViewDoneBtnDisableTitleColorOfPreviewVC: UIColor {
        ZLPhotoUIConfiguration.default().bottomToolViewDoneBtnDisableTitleColorOfPreviewVC
    }

    static var bottomToolViewBtnNormalBgColor: UIColor {
        ZLPhotoUIConfiguration.default().bottomToolViewBtnNormalBgColor
    }

    static var bottomToolViewBtnNormalBgColorOfPreviewVC: UIColor {
        ZLPhotoUIConfiguration.default().bottomToolViewBtnNormalBgColorOfPreviewVC
    }

    static var bottomToolViewBtnDisableBgColor: UIColor {
        ZLPhotoUIConfiguration.default().bottomToolViewBtnDisableBgColor
    }

    static var bottomToolViewBtnDisableBgColorOfPreviewVC: UIColor {
        ZLPhotoUIConfiguration.default().bottomToolViewBtnDisableBgColorOfPreviewVC
    }

    static var limitedAuthorityTipsColor: UIColor {
        return ZLPhotoUIConfiguration.default().limitedAuthorityTipsColor
    }

    static var cameraRecodeProgressColor: UIColor {
        ZLPhotoUIConfiguration.default().cameraRecodeProgressColor
    }

    static var selectedMaskColor: UIColor {
        ZLPhotoUIConfiguration.default().selectedMaskColor
    }

    static var selectedBorderColor: UIColor {
        ZLPhotoUIConfiguration.default().selectedBorderColor
    }

    static var invalidMaskColor: UIColor {
        ZLPhotoUIConfiguration.default().invalidMaskColor
    }

    static var indexLabelTextColor: UIColor {
        ZLPhotoUIConfiguration.default().indexLabelTextColor
    }

    static var indexLabelBgColor: UIColor {
        ZLPhotoUIConfiguration.default().indexLabelBgColor
    }

    static var cameraCellBgColor: UIColor {
        ZLPhotoUIConfiguration.default().cameraCellBgColor
    }

    static var adjustSliderNormalColor: UIColor {
        ZLPhotoUIConfiguration.default().adjustSliderNormalColor
    }

    static var adjustSliderTintColor: UIColor {
        ZLPhotoUIConfiguration.default().adjustSliderTintColor
    }

    static var imageEditorToolTitleNormalColor: UIColor {
        ZLPhotoUIConfiguration.default().imageEditorToolTitleNormalColor
    }

    static var imageEditorToolTitleTintColor: UIColor {
        ZLPhotoUIConfiguration.default().imageEditorToolTitleTintColor
    }

    static var imageEditorToolIconTintColor: UIColor? {
        ZLPhotoUIConfiguration.default().imageEditorToolIconTintColor
    }

    static var trashCanBackgroundNormalColor: UIColor {
        ZLPhotoUIConfiguration.default().trashCanBackgroundNormalColor
    }

    static var trashCanBackgroundTintColor: UIColor {
        ZLPhotoUIConfiguration.default().trashCanBackgroundTintColor
    }
}

extension ZLPhotoBrowserWrapper where Base: UIColor {





    static func rgba(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> UIColor {
        return UIColor(red: r / 255, green: g / 255, blue: b / 255, alpha: a)
    }
}
