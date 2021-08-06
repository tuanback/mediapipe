MIN_IOS_VERSION = "10.0"

load("@build_bazel_rules_apple//apple:ios.bzl", "ios_framework")

ios_framework(
    name = "MediapipeObjectTracker",
    hdrs = [
        "Detection.pbobjc.h",
        "ObjectTracker.h",
    ],
    infoplists = ["Info.plist"],
    bundle_id = "ai.3i.ObjectTracker",
    families = ["iphone", "ipad"],
    minimum_os_version = "10.0",
    deps = [
        ":ObjectTrackerLibrary",
        "@ios_opencv//:OpencvFramework",
    ],
)

objc_library(
    name = "ObjectTrackerLibrary",
    srcs = [
        "ObjectTracker.mm",
    ],
    hdrs = [
        "ObjectTracker.h",
    ],
    copts = ["-std=c++17"],
    data = [
        "//mediapipe/graphs/experiment:mobile_gpu_binary_graph",
        "//mediapipe/models:ssdlite_object_detection.tflite",
        "//mediapipe/models:ssdlite_object_detection_labelmap.txt",
    ],
    sdk_frameworks = [
        "UIKit",
        "AVFoundation",
        "CoreGraphics",
        "CoreMedia",
    ],
    deps = [
        "//mediapipe/objc:mediapipe_framework_ios",
    ] + select({
        "//mediapipe:ios_i386": [],
        "//mediapipe:ios_x86_64": [],
        "//conditions:default": [
            ":DetectionClass",
            "//mediapipe/graphs/experiment:mobile_calculators",
            "//mediapipe/framework/formats:detection_cc_proto",
        ],
    }),
)

objc_library(
    name = "DetectionClass",
    srcs = [
        "Detection.pbobjc.m",
    ],
    hdrs = [
        "Detection.pbobjc.h",
    ],
    data = [
    ],
    sdk_frameworks = [
        "UIKit",
        "AVFoundation",
        "CoreGraphics",
        "CoreMedia",
    ],
    deps = [

    ],
)