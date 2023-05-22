# About

I made this app because I've wanted an app just like it.

I had no development experience so I took it as a learning project. What does it take to go from idea to App Store?
 
### Challenge

To answer that question, I set myself a key challenge:

> Do everything myself, take no shortcuts.

### Learning

This meant writing every single line of code myself without dependencies. It meant learning some design and coming up with an app icon. It meant creating mockups and wireframes, talking to users, prioritizing features, handling finances, and so much more.

In hindsight, this was the best decision I could've made. 

## Note

> **Note**  
> This was my very first app without prior experience. Keep that in mind when checking out the code  😉 

## Technical Challenges

While Frame Grabber might look simple at first glance, there are lots of details behind the scenes for a good UX.

Here are a few examples.

<details>
 <summary><h3>Interactive Transitions</h3></summary>
 
https://github.com/arthurhammer/FrameGrabber/assets/4521216/d9fc007d-d94e-4903-8383-e78ee1070eb7

The editor-to-library transition gives the user a sense of context when navigating between screens.

There was zero reference material for transitions with such complexity. I developed it from scratch, sweating every detail and covering a multitude of edge cases to get it just right. One particular challenge was in making the transition between moving video and static thumbnail feel natural. 


🔗 [Code](/Frame%20Grabber/Other/Transition/)

</details>

<details>

 <summary><h3>Custom Controls</h3></summary>

https://github.com/arthurhammer/FrameGrabber/assets/4521216/bd642770-437b-47ae-82b1-2b54179ec093


The video slider is a key UI element in the editor. It should be intuitive yet precise. 

I created a fully custom, reusable component. It supports asynchronous thumbnail loading from any data source, interactive scrubbing speeds and accessibility. Thumbnails show interesting moments at a glance. For precise selection, custom speeds can be set.

🔗 [Code](/Frame%20Grabber/Packages/ThumbnailSlider/Sources/ThumbnailSlider/) and [blog post](https://arthurhammer.de/2020/03/uislider-with-scrubbing-speeds/)

</details>

<details>
 <summary><h3>Efficient Frame Export</h3></summary>

https://github.com/arthurhammer/FrameGrabber/assets/4521216/988e9f1a-825a-4be5-83e8-97ca4fb5ff71

Decoding and exporting even just a handful of 4k video frames consumes immense amounts of memory leading to potential crashes.

I created a `FrameExport` service based on `OperationQueue` that exports frames in configurable batches and synchronizes the results. It supports arbitrary numbers of frames, cancellation and progress reporting.


🔗 [Code](/Frame%20Grabber/Services/Frame%20Export/)

</details>


<details>
 <summary><h3>Frame-Time Indexing</h3></summary>

https://github.com/arthurhammer/FrameGrabber/assets/4521216/fb7c31b3-a725-4680-b45a-4abd951595e1

The editor shows the video time in the `mm:ss.ff` format. This format uniquely identifies any frame helping users in comparing frames.

Calculating this number required indexing every single frame in a video, which can be in the hundreds of thousands. Once indexed, a custom binary search ensures efficient retrieval of a specific time. Using `AVFoundation` and `OperationQueue`, the entire process is done fully in the background hidden from the user.


🔗 [Code](/Frame%20Grabber/Packages/SampleTimeIndexer/Sources/SampleTimeIndexer/)
and [unit tests](/Frame%20Grabber/Packages/SampleTimeIndexer/Tests/SampleTimeIndexerTests/)

</details>

### And Much More…
