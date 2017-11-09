//
//  ActionViewController.swift
//  Frame Grabber Action Extension
//
//  Created by Arthur Hammer on 16.11.2017.
//  Copyright © 2017 Arthur Hammer. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVKit

class ActionViewController: UIViewController {

    private var videoPlayerViewController: AVPlayerViewController!
//    private var player = Player()

    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Get the item[s] we're handling from the extension context.

        print(self.extensionContext!.inputItems)

        // For example, look for an image and place it into an image view.
        // Replace this with something appropriate for the type[s] your extension supports.
        var imageFound = false
        for item in self.extensionContext!.inputItems as! [NSExtensionItem] {
            for provider in item.attachments! as! [NSItemProvider] {
                if provider.hasItemConformingToTypeIdentifier(kUTTypeMovie as String) {
                    // This is an image. We'll load it, then place it in our image view.

                    provider.loadItem(forTypeIdentifier: kUTTypeMovie as String, options: nil) { videoUrl, error in
                        print(videoUrl)
                        print(error)

                        guard let url = videoUrl as? URL else {
                            // handle error
                            return
                        }

//                        let asset = AVAsset(url: url)

                        // weak
                        DispatchQueue.main.async {
                            self.videoPlayerViewController.player = AVPlayer(url: url)
                        }
                    }
                    
                    imageFound = true
                    break
                }
            }
            
            if (imageFound) {
                // We only handle one image, so stop looking for more.
                break
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? AVPlayerViewController {
            videoPlayerViewController = controller
        }
    }

    @IBAction func shareVideoFrame() {
        videoPlayerViewController.player?.pause()
        guard let asset = videoPlayerViewController.player?.currentItem?.asset,
            let time = videoPlayerViewController.player?.currentTime() else { return }

        let imageGenerator = AVAssetImageGenerator(asset: asset)

        imageGenerator.copyCGImage(atExactTime: time) { error, cgImage in
            guard let cgImage = cgImage else {
                // TODO: custom message
                print("error", error)
                return
            }

            shareImage(UIImage(cgImage: cgImage))
        }
        
    }

    func shareImage(_ image: UIImage) {
        let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(activityController, animated: true)
    }

    @IBAction func done() {
        // Return any edited content to the host app.
        // This template doesn't do anything, so we just echo the passed in items.
        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
    }

}
