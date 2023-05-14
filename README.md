<p align="center">
    <a href="https://apps.apple.com/app/frame-grabber/id1434703541">
        <img src="design/banner.jpg" alt="App Store banner.">
    </a>
</p>
<p align="center">
    <a href="https://apps.apple.com/app/frame-grabber/id1434703541">
        <img src="./design/app-store-badge.svg" alt="Download on the App Store">
    </a>
</p>

[Frame Grabber](https://framegrabberapp.com) is an app for iOS & iPadOS to extract full-resolution video frames as images — [framegrabberapp.com](https://framegrabberapp.com)

## About

**Why**:
- I wanted this app for myself (existing apps were not great)

**Challenge**:
- Learn iOS development
- No 3rd-party dependencies allowed, do everything myself
- Make the best app of its kind

**Results**:
- 4.8 stars worldwide
- Loved by users for its UX and ease-of-use
- Consistent monthly income

## Building

- Open Xcode
- Change development team and bundle identifier
- Build

## Project Setup

> **Warning**  
> This code is from my very first project before I knew anything about professional iOS development, tight coupling, dependency injection, or SOLID.

To learn the fundamentals, I decided to stick to Apple's documentation. 

The project uses MVC with storyboards. A few parts use view models. The Coordinator pattern navigates from scene to scene. iPadOS-specific layouts are implemented with size classes in code and in storyboards. Layouts support Dynamic Type and Accessibility.

Main components:
- [`Application`](Frame%20Grabber/Application): Entry point into the app
- [`Scenes`](Frame%20Grabber/Scenes):The app's main screens
- [`Packages`](Frame%20Grabber/Packages): Modules extracted so far
- [`SampleTimeIndexerTests`](Frame%20Grabber/Packages/SampleTimeIndexer/Tests/SampleTimeIndexerTests/): Some tests for a critical part of the app

## Contact

Feedback welcome! — hi@arthurhammer.de

## License

See [`LICENSE`](LICENSE).

Please don't make it weird and [publish a clone](https://github.com/arthurhammer/FrameGrabber/issues/5) to the App Store. If you want to improve the app, I'd love to hear your feedback 🤗
