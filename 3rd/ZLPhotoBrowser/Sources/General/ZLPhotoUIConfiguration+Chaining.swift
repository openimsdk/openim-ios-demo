

























import UIKit


public extension ZLPhotoUIConfiguration {
    @discardableResult
    func sortAscending(_ ascending: Bool) -> ZLPhotoUIConfiguration {
        sortAscending = ascending
        return self
    }
    
    @discardableResult
    func style(_ style: ZLPhotoBrowserStyle) -> ZLPhotoUIConfiguration {
        self.style = style
        return self
    }
    
    @discardableResult
    func statusBarStyle(_ statusBarStyle: UIStatusBarStyle) -> ZLPhotoUIConfiguration {
        self.statusBarStyle = statusBarStyle
        return self
    }
    
    @discardableResult
    func navCancelButtonStyle(_ style: ZLPhotoUIConfiguration.CancelButtonStyle) -> ZLPhotoUIConfiguration {
        navCancelButtonStyle = style
        return self
    }
    
    @discardableResult
    func showStatusBarInPreviewInterface(_ value: Bool) -> ZLPhotoUIConfiguration {
        showStatusBarInPreviewInterface = value
        return self
    }
    
    @discardableResult
    func hudStyle(_ style: ZLProgressHUD.Style) -> ZLPhotoUIConfiguration {
        hudStyle = style
        return self
    }
    
    @discardableResult
    func adjustSliderType(_ type: ZLAdjustSliderType) -> ZLPhotoUIConfiguration {
        adjustSliderType = type
        return self
    }
    
    @discardableResult
    func cellCornerRadio(_ cornerRadio: CGFloat) -> ZLPhotoUIConfiguration {
        cellCornerRadio = cornerRadio
        return self
    }
    
    @discardableResult
    func customAlertClass(_ alertClass: ZLCustomAlertProtocol.Type?) -> ZLPhotoUIConfiguration {
        customAlertClass = alertClass
        return self
    }

    @discardableResult
    func columnCount(_ count: Int) -> ZLPhotoUIConfiguration {
        columnCount = count
        return self
    }
    
    @discardableResult
    func columnCountBlock(_ block: ((_ collectionViewWidth: CGFloat) -> Int)?) -> ZLPhotoUIConfiguration {
        columnCountBlock = block
        return self
    }
    
    @discardableResult
    func minimumInteritemSpacing(_ value: CGFloat) -> ZLPhotoUIConfiguration {
        minimumInteritemSpacing = value
        return self
    }
    
    @discardableResult
    func minimumLineSpacing(_ value: CGFloat) -> ZLPhotoUIConfiguration {
        minimumLineSpacing = value
        return self
    }
    
    @discardableResult
    func animateSelectBtnWhenSelectInThumbVC(_ animate: Bool) -> ZLPhotoUIConfiguration {
        animateSelectBtnWhenSelectInThumbVC = animate
        return self
    }
    
    @discardableResult
    func animateSelectBtnWhenSelectInPreviewVC(_ animate: Bool) -> ZLPhotoUIConfiguration {
        animateSelectBtnWhenSelectInPreviewVC = animate
        return self
    }
    
    @discardableResult
    func selectBtnAnimationDuration(_ duration: CFTimeInterval) -> ZLPhotoUIConfiguration {
        selectBtnAnimationDuration = duration
        return self
    }
    
    @discardableResult
    func showIndexOnSelectBtn(_ value: Bool) -> ZLPhotoUIConfiguration {
        showIndexOnSelectBtn = value
        return self
    }
    
    @discardableResult
    func showScrollToBottomBtn(_ value: Bool) -> ZLPhotoUIConfiguration {
        showScrollToBottomBtn = value
        return self
    }
    
    @discardableResult
    func showCaptureImageOnTakePhotoBtn(_ value: Bool) -> ZLPhotoUIConfiguration {
        showCaptureImageOnTakePhotoBtn = value
        return self
    }
    
    @discardableResult
    func showSelectedMask(_ value: Bool) -> ZLPhotoUIConfiguration {
        showSelectedMask = value
        return self
    }
    
    @discardableResult
    func showSelectedBorder(_ value: Bool) -> ZLPhotoUIConfiguration {
        showSelectedBorder = value
        return self
    }
    
    @discardableResult
    func showInvalidMask(_ value: Bool) -> ZLPhotoUIConfiguration {
        showInvalidMask = value
        return self
    }
    
    @discardableResult
    func showSelectedPhotoPreview(_ value: Bool) -> ZLPhotoUIConfiguration {
        showSelectedPhotoPreview = value
        return self
    }
    
    @discardableResult
    func showAddPhotoButton(_ value: Bool) -> ZLPhotoUIConfiguration {
        showAddPhotoButton = value
        return self
    }
    
    @discardableResult
    func showEnterSettingTips(_ value: Bool) -> ZLPhotoUIConfiguration {
        showEnterSettingTips = value
        return self
    }
    
    @discardableResult
    func timeout(_ timeout: TimeInterval) -> ZLPhotoUIConfiguration {
        self.timeout = timeout
        return self
    }
    
    @discardableResult
    func navViewBlurEffectOfAlbumList(_ effect: UIBlurEffect?) -> ZLPhotoUIConfiguration {
        navViewBlurEffectOfAlbumList = effect
        return self
    }
    
    @discardableResult
    func navViewBlurEffectOfPreview(_ effect: UIBlurEffect?) -> ZLPhotoUIConfiguration {
        navViewBlurEffectOfPreview = effect
        return self
    }
    
    @discardableResult
    func bottomViewBlurEffectOfAlbumList(_ effect: UIBlurEffect?) -> ZLPhotoUIConfiguration {
        bottomViewBlurEffectOfAlbumList = effect
        return self
    }
    
    @discardableResult
    func bottomViewBlurEffectOfPreview(_ effect: UIBlurEffect?) -> ZLPhotoUIConfiguration {
        bottomViewBlurEffectOfPreview = effect
        return self
    }
    
    @discardableResult
    func customImageNames(_ names: [String]) -> ZLPhotoUIConfiguration {
        customImageNames = names
        return self
    }
    
    @discardableResult
    func customImageForKey(_ map: [String: UIImage?]) -> ZLPhotoUIConfiguration {
        customImageForKey = map
        return self
    }
    
    @discardableResult
    func languageType(_ type: ZLLanguageType) -> ZLPhotoUIConfiguration {
        languageType = type
        return self
    }
    
    @discardableResult
    func customLanguageKeyValue(_ map: [ZLLocalLanguageKey: String]) -> ZLPhotoUIConfiguration {
        customLanguageKeyValue = map
        return self
    }
    
    @discardableResult
    func themeFontName(_ name: String) -> ZLPhotoUIConfiguration {
        themeFontName = name
        return self
    }
    
    @discardableResult
    func themeColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        themeColor = color
        return self
    }
    
    @discardableResult
    func sheetTranslucentColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        sheetTranslucentColor = color
        return self
    }
    
    @discardableResult
    func sheetBtnBgColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        sheetBtnBgColor = color
        return self
    }
    
    @discardableResult
    func sheetBtnTitleColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        sheetBtnTitleColor = color
        return self
    }
    
    @discardableResult
    func sheetBtnTitleTintColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        sheetBtnTitleTintColor = color
        return self
    }
    
    @discardableResult
    func navBarColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        navBarColor = color
        return self
    }
    
    @discardableResult
    func navBarColorOfPreviewVC(_ color: UIColor) -> ZLPhotoUIConfiguration {
        navBarColorOfPreviewVC = color
        return self
    }
    
    @discardableResult
    func navTitleColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        navTitleColor = color
        return self
    }
    
    @discardableResult
    func navTitleColorOfPreviewVC(_ color: UIColor) -> ZLPhotoUIConfiguration {
        navTitleColorOfPreviewVC = color
        return self
    }
    
    @discardableResult
    func navEmbedTitleViewBgColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        navEmbedTitleViewBgColor = color
        return self
    }
    
    @discardableResult
    func albumListBgColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        albumListBgColor = color
        return self
    }
    
    @discardableResult
    func embedAlbumListTranslucentColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        embedAlbumListTranslucentColor = color
        return self
    }
    
    @discardableResult
    func albumListTitleColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        albumListTitleColor = color
        return self
    }
    
    @discardableResult
    func albumListCountColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        albumListCountColor = color
        return self
    }
    
    @discardableResult
    func separatorColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        separatorColor = color
        return self
    }
    
    @discardableResult
    func thumbnailBgColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        thumbnailBgColor = color
        return self
    }
    
    @discardableResult
    func previewVCBgColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        previewVCBgColor = color
        return self
    }
    
    @discardableResult
    func bottomToolViewBgColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        bottomToolViewBgColor = color
        return self
    }
    
    @discardableResult
    func bottomToolViewBgColorOfPreviewVC(_ color: UIColor) -> ZLPhotoUIConfiguration {
        bottomToolViewBgColorOfPreviewVC = color
        return self
    }
    
    @discardableResult
    func originalSizeLabelTextColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        originalSizeLabelTextColor = color
        return self
    }
    
    @discardableResult
    func originalSizeLabelTextColorOfPreviewVC(_ color: UIColor) -> ZLPhotoUIConfiguration {
        originalSizeLabelTextColorOfPreviewVC = color
        return self
    }
    
    @discardableResult
    func bottomToolViewBtnNormalTitleColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        bottomToolViewBtnNormalTitleColor = color
        return self
    }
    
    @discardableResult
    func bottomToolViewDoneBtnNormalTitleColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        bottomToolViewDoneBtnNormalTitleColor = color
        return self
    }
    
    @discardableResult
    func bottomToolViewBtnNormalTitleColorOfPreviewVC(_ color: UIColor) -> ZLPhotoUIConfiguration {
        bottomToolViewBtnNormalTitleColorOfPreviewVC = color
        return self
    }
    
    @discardableResult
    func bottomToolViewDoneBtnNormalTitleColorOfPreviewVC(_ color: UIColor) -> ZLPhotoUIConfiguration {
        bottomToolViewDoneBtnNormalTitleColorOfPreviewVC = color
        return self
    }
    
    @discardableResult
    func bottomToolViewBtnDisableTitleColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        bottomToolViewBtnDisableTitleColor = color
        return self
    }
    
    @discardableResult
    func bottomToolViewDoneBtnDisableTitleColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        bottomToolViewDoneBtnDisableTitleColor = color
        return self
    }
    
    @discardableResult
    func bottomToolViewBtnDisableTitleColorOfPreviewVC(_ color: UIColor) -> ZLPhotoUIConfiguration {
        bottomToolViewBtnDisableTitleColorOfPreviewVC = color
        return self
    }
    
    @discardableResult
    func bottomToolViewDoneBtnDisableTitleColorOfPreviewVC(_ color: UIColor) -> ZLPhotoUIConfiguration {
        bottomToolViewDoneBtnDisableTitleColorOfPreviewVC = color
        return self
    }
    
    @discardableResult
    func bottomToolViewBtnNormalBgColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        bottomToolViewBtnNormalBgColor = color
        return self
    }
    
    @discardableResult
    func bottomToolViewBtnNormalBgColorOfPreviewVC(_ color: UIColor) -> ZLPhotoUIConfiguration {
        bottomToolViewBtnNormalBgColorOfPreviewVC = color
        return self
    }
    
    @discardableResult
    func bottomToolViewBtnDisableBgColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        bottomToolViewBtnDisableBgColor = color
        return self
    }
    
    @discardableResult
    func bottomToolViewBtnDisableBgColorOfPreviewVC(_ color: UIColor) -> ZLPhotoUIConfiguration {
        bottomToolViewBtnDisableBgColorOfPreviewVC = color
        return self
    }
    
    @discardableResult
    func limitedAuthorityTipsColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        limitedAuthorityTipsColor = color
        return self
    }
    
    @discardableResult
    func cameraRecodeProgressColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        cameraRecodeProgressColor = color
        return self
    }
    
    @discardableResult
    func selectedMaskColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        selectedMaskColor = color
        return self
    }
    
    @discardableResult
    func selectedBorderColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        selectedBorderColor = color
        return self
    }
    
    @discardableResult
    func invalidMaskColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        invalidMaskColor = color
        return self
    }
    
    @discardableResult
    func indexLabelTextColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        indexLabelTextColor = color
        return self
    }
    
    @discardableResult
    func indexLabelBgColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        indexLabelBgColor = color
        return self
    }
    
    @discardableResult
    func cameraCellBgColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        cameraCellBgColor = color
        return self
    }
    
    @discardableResult
    func adjustSliderNormalColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        adjustSliderNormalColor = color
        return self
    }
    
    @discardableResult
    func adjustSliderTintColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        adjustSliderTintColor = color
        return self
    }
    
    @discardableResult
    func imageEditorToolTitleNormalColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        imageEditorToolTitleNormalColor = color
        return self
    }
    
    @discardableResult
    func imageEditorToolTitleTintColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        imageEditorToolTitleTintColor = color
        return self
    }
    
    @discardableResult
    func imageEditorToolIconTintColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        imageEditorToolIconTintColor = color
        return self
    }
    
    @discardableResult
    func trashCanBackgroundNormalColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        trashCanBackgroundNormalColor = color
        return self
    }
    
    @discardableResult
    func trashCanBackgroundTintColor(_ color: UIColor) -> ZLPhotoUIConfiguration {
        trashCanBackgroundTintColor = color
        return self
    }
}
