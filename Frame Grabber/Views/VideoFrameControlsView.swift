import UIKit

class VideoFrameControlsView: UIView {

    @IBOutlet var previousFrameButtonItem: UIBarButtonItem!
    @IBOutlet var nextFrameButtonItem: UIBarButtonItem!
    @IBOutlet var shareButtonItem: UIBarButtonItem!
    @IBOutlet var doneButtonItem: UIBarButtonItem!

    @IBOutlet var currentTimeLabel: MonospacedDigitLabel!
    @IBOutlet var videoDimensionsLabel: MonospacedDigitLabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    private func configureViews() {
        backgroundColor = .mainBackground

        let size: CGFloat = 14
        let weight = UIFont.Weight.semibold
        let color = UIColor.white  

        currentTimeLabel.fontSize = size
        currentTimeLabel.fontWeight = weight
        currentTimeLabel.textColor = color
        currentTimeLabel.text = nil

        videoDimensionsLabel.fontSize = size
        videoDimensionsLabel.fontWeight = weight
        videoDimensionsLabel.textColor = color
        videoDimensionsLabel.text = nil
    }
}
