import SwiftUI
import TipKit

/// One-time hints for gestures that are easy to miss. TipKit stops showing each one once it's used.
struct RemoveSetTip: Tip {
    var title: Text {
        Text("Remove a set")
    }

    var message: Text? {
        Text("Swipe a set to the left to remove it. You can undo straight away.")
    }

    var image: Image? {
        Image(systemName: "hand.draw")
    }
}

struct CountRepsTip: Tip {
    var title: Text {
        Text("Let the camera count")
    }

    var message: Text? {
        Text("Prop your phone up, step back so your whole body is in view, and it counts your reps for you.")
    }

    var image: Image? {
        Image(systemName: "camera.viewfinder")
    }
}

struct ReorderExercisesTip: Tip {
    var title: Text {
        Text("Change the order")
    }

    var message: Text? {
        Text("Tap Edit, then drag an exercise by its handle.")
    }

    var image: Image? {
        Image(systemName: "arrow.up.arrow.down")
    }
}
