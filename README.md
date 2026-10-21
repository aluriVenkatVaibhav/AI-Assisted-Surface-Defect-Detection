# Portable Windows x64 trial - pehle yeh padho

1. ZIP par **Extract All** karo. App ZIP ke andar se mat chalao.
2. **START_APP.cmd** double-click karo. Python, compiler aur training ki zaroorat nahi.
3. **RUN_CHECKS.cmd** double-click karo. Geometry/features, real video synchronization aur
   actual OpenGL rendering checks chalenge. Screenshots aur log **checks/** mein milenge.
4. Apni image/video try karne ke liye app mein **Open image / Open video** use karo.
   Sample video: **outputs/demo_sequence.avi**. Wheel zoom, right-drag pan, rotation slider,
   region picking, ROI drawing/clipping aur ground-truth toggle try karo.

Target: **Windows 10/11 64-bit, graphics driver supporting OpenGL 3.3**.
This is the same real trained pipeline; it does not retrain on launch.

Included: executable + required DLLs, saved model/configuration, full C++ project source,
29 real held-out sample image/mask pairs (25 normal / 4 defective),
24-frame still-image video demonstration, original measured results and screenshots.
**DEMO_SAMPLES.csv** contains labels and reference predictions, including real mistakes.
The full 853 MB dataset ZIP is omitted. The included subset is for trial and debugging;
it cannot reproduce full test metrics by itself. For full training/evaluation, first download
the complete dataset using **tools/prepare_dataset.py**, then follow the build commands below.

Feedback mein yeh bhejna: app khula ya nahi; image/video, zoom/pan/rotation, ROI/picking mein
koi bug; suspicious prediction ka image ID; aur **checks/check_log.txt**.
Model perfect nahi hai: the official full test had 48 false alarms and 22 misses. Candidate
localization has mean Dice 0.296. The video is a dataset-stills demonstration, not independent
video evaluation. The measurements below are from the original machine, not your machine.

Original reference results are in **outputs/**; this computer's fresh checks go into **checks/**.
Dependency notices/licences and source/build-recipe links are in **third_party/**.

---

# AI-Assisted Surface Defect Detection and Interactive Visualization

**Theme 6: Computer Vision-Based Image and Video Analysis with Graphics Visualization**  
Interactive Computer Graphics course project, **IIITDM Kancheepuram**.

| Team member | Roll number |
|---|---|
| Gyan Chandra | CS23I1053 |
| Vaibhav | CS23I1040 |
| Vishal Singh | CS23I1039 |

The implementation has three areas: `pipeline.cpp` / `evaluation.cpp` handle dataset validation, DIP, features, classifiers and evaluation; `geometry.cpp` / `viewer.cpp` handle OpenGL rendering and interaction; `integration.cpp` / `main.cpp` handle asynchronous analysis, video and application commands. These are module responsibilities, not claims about individual contributions.

## Build and run (PowerShell, project directory)

The verified toolchain uses the installed MSYS2 MinGW64 GCC, with matching project-local MSYS2 libraries. Do not use MSVC libraries with this build. Dependency setup downloads official MSYS2 packages, verifies repository SHA-256 checksums and resolves runtime DLL imports. Dear ImGui is pinned to 1.91.9b. Python 3.14 provides the setup script's `compression.zstd` module.

```powershell
& 'C:\msys64\mingw64\bin\python.exe' tools\setup_dependencies.py
& 'C:\msys64\mingw64\bin\python.exe' tools\prepare_dataset.py
.\tools\build.ps1
.\tools\run.ps1 prepare
.\tools\run.ps1 train
.\tools\run.ps1 demo-video
.\tools\run.ps1 verify
.\tools\run.ps1 view --smoke
.\tools\run.ps1 view
```

`build.ps1` limits compilation to two jobs and runs CTest. `run.ps1` configures the DLL search path. `view` loads `outputs/model`; it never trains. `prepare`, `train`, `evaluate`, `predict`, `demo-video`, and `verify` do not initialize GLFW or an OpenGL context.

```powershell
# Repeat only final evaluation with the saved pipeline:
.\tools\run.ps1 evaluate
# Infer from an arbitrary image, without any annotation:
.\tools\run.ps1 predict --image 'C:\path\surface.png'
# Override locations when needed:
.\tools\run.ps1 view --model outputs\model --data data\KolektorSDD2
```

## Dataset and method

[KolektorSDD2, ViCoS Lab](https://www.vicos.si/resources/kolektorsdd2/) is downloaded from the [official ZIP](https://data.vicos.si/datasets/KSDD/KolektorSDD2.zip) to `data/KolektorSDD2.zip` and safely extracted under `data/KolektorSDD2/`. Downloads stream to disk, use bounded timeouts/retries and up to four range requests, retain partial files, reject wrong content/size, and pass ZIP CRC checks before extraction. `data/source.json` records the URL, UTC download date, size and SHA-256. Raw files are preserved.

Canonical numeric image names must pair with `<id>_GT.png`: **2,331 training images (246 defective / 2,085 normal)** and **1,004 test images (110 defective / 894 normal)**. Every pair is decoded and dimension-checked. Targets come only from mask foreground. Copy-named files and other auxiliary entries are excluded from labelled samples and documented in `outputs/dataset_audit.txt`; `.pyb` files are never executed or deserialized.

The pipeline converts BGR to grayscale, resizes to 224 x 608, denoises, applies CLAHE, computes Sobel gradients and background/morphological residuals, and extracts **110 bounded features**. These include distribution statistics, fixed image cells and ranked patch statistics; patches are aggregated into one image feature vector. The ablation removes the 59 residual/texture features. Features receive only image pixels and configuration, never masks, IDs or label-dependent crops.

Decoded source images are SHA-256 grouped before a seeded (20261013), stratified 80/20 development split. Identical sources stay together; any training source duplicated in the test set is excluded from development. Standardization and class imbalance weights are fitted on the fit subset only. The bounded search compares weighted Random Forests (200 trees, depth 10/16), weighted RBF SVMs (C=1/10), and a majority baseline. Validation F2, with F1 as tie-breaker, selects the feature variant, model and threshold. The selected fit-subset model is retained without refitting on validation, so its selected threshold keeps the same score distribution. The pipeline is saved and locked before official test evaluation. Reloaded scores and image-derived features are checked for consistency.

Localization is a **separate image-based candidate method**, using black/top-hat response, gradient support, thresholding, closing, border suppression and connected components. Threshold 12/20/30/45 and minimum area 8/24 are selected on validation using defective-image mean Dice minus twice normal-image false-positive area. Predicted contours are suspected areas, not confirmed defects. Classifier scores are uncalibrated tree vote fractions or oriented SVM margins. Pixel areas are not physical measurements.

## Viewer and graphics

Images are RGB OpenGL textures; contours, boxes and ROI edges are OpenGL line primitives, rendered with one OpenGL 3.3 shader pipeline and GLEW loader. Pixel unpack alignment, top-left image coordinates, logical-window/framebuffer scaling and aspect ratio are handled explicitly. A homogeneous image-to-screen matrix applies centering, scale, rotation and translation; its inverse maps mouse input into image coordinates. Liang–Barsky clips overlay segments in image coordinates at the ROI boundary before transformation.

- Open or drag/drop an image/video; browse canonical dataset images.
- Switch original, processed and predicted-overlay views.
- Mouse wheel zooms about the cursor; right/middle drag pans; sliders rotate/zoom; reset fits the image.
- Left click selects a suspected region. Enable ROI drawing (or hold Shift) and left-drag; green ROI clips candidate geometry.
- Optional **purple ground truth** is explicitly labelled for evaluation, separate from **orange predicted candidates**.
- Video supports play/pause, frame step and rewind. Decode and analysis run on a worker with one pending request and tagged source/frame results. Displayed source information accompanies the displayed frame; obsolete results are discarded.
- About includes all three exact team names and roll numbers.

`demo-video` makes a 24-frame MJPEG image-sequence demonstration from real dataset stills. It is **not independent video evaluation**. Playback processes every requested frame and can run below the source rate; memory/queues remain bounded.

## Measured results and verification

Actual run results are saved in `outputs/model_comparison.csv`, `localization_validation.csv`, `training_summary.json`, `final_test.json`, `confusion_matrix.csv`, `test_predictions.csv` and `test_localization.csv`. Representative TP/TN/FP/FN panels are in `outputs/examples/`. Genuine OpenGL framebuffer screenshots are in `outputs/screenshots/`; `graphics_smoke.json` reports GPU-synchronized rendering separately from analysis. `runtime_checks.json` records real decoded-frame synchronization and image-only inference checks.

Verified on Windows 11 Home (10.0.26200), Ryzen 5 6600H, approximately 16 GB installed memory (about 3.8 GiB free during setup), GCC 16.2.0, OpenCV 5.0.0, GLFW 3.5.1, GLEW 2.3.1 and AMD Radeon 660M OpenGL 3.3. The archive SHA-256 is `edcdb486809b24f1d17b785e30c52fafc5999554dd5fe18ddf77b61ceb6f36a8`, downloaded 13 October 2026. The extra image exactly matches canonical `train/10301`; it is excluded, as is its auxiliary mask copy. No duplicate canonical sources or train/test overlap were found. The fit/validation counts are **1,865 / 466**.

| Validation comparison | Defect precision | Defect recall | F1 | F2 | ROC AUC |
|---|---:|---:|---:|---:|---:|
| Majority baseline | 0% | 0% | 0 | 0 | 0.5000 |
| Full Random Forest, depth 16 (best RF by F2) | 71.15% | 75.51% | 0.7327 | 0.7460 | 0.9155 |
| **Full SVM, C=1 (selected)** | **68.42%** | **79.59%** | **0.7358** | **0.7708** | **0.9116** |
| Same SVM without residual/texture features | 53.13% | 69.39% | 0.6018 | 0.6538 | 0.8909 |

All eight bounded candidates are recorded in `model_comparison.csv`. The selected SVM uses gamma=1/110 and oriented-margin threshold **-0.0818076879**. The maximum saved/reloaded validation score difference was **0**. Twelve annotation-free feature reconstructions matched the training feature matrix; separate runtime checks also confirmed inference from an image copied without any mask.

**Official test (1,004 images): precision 64.71%, recall 80.00%, F1 0.7154, F2 0.7639, ROC AUC 0.9383, average precision 0.8069.** Accuracy is 93.03%; the majority baseline has 89.04% accuracy but detects no defects. There are **48 false alarms (5.37% of normal images)** and **22 missed defective images**.

| Actual / predicted | Normal | Defective |
|---|---:|---:|
| Normal | 846 | 48 |
| Defective | 22 | 88 |

Localization uses threshold 30 and minimum resized-component area 24. On the 110 defective test images, **mean IoU = 0.2042, mean Dice = 0.2959**, aggregated pixel precision = 92.48%, and pixel recall = 15.39%. On the 894 normal images, the mean predicted foreground fraction is **0.02793%**. This conservative method localizes only a small part of many defects; its low recall is a material limitation even when image-level classification succeeds.

Measured test stages, excluding image decoding: **features + preprocessing 40.64 ms/image**, **batch prediction 0.039 ms/image**, and **localization 14.16 ms/image**. Feature/prediction throughput was 24.59 images/s. Development (including dataset validation, extraction, eight fits and localization tuning) took 281.22 s; individual fit times are in the comparison CSV. Viewer analysis also prepares its processed display texture: the five smoke-test image/frame analyses averaged **53.45 ms**. GPU-synchronized rendering averaged **0.55 ms** (p95 **0.486 ms**) over **582 frames with image content**. These measurements are saved separately in `graphics_smoke.json`.

Core tests passed 500 transform/inverse/picking cases, clipping parallel/boundary/tangent/zero-length cases and 500 reversal checks, feature/channel/ablation/scaling consistency, invalid inputs and localization dimensions. Runtime verification passed missing/corrupt inputs, latest-request isolation, image-only inference, **six actual decoded video frames and a seek**, with maximum frame-score difference **0**. The real OpenGL smoke test exercised rotation, zoom, pan, picking, ROI clipping, resize and four video frames, and saved **six genuine framebuffer captures**, including the About team panel. Nine source-pixel checks differed by at most **one channel value**. Rendering timings use `glFinish`, exclude initial blank loading frames and evaluation-mask decoding, and do not represent video-analysis throughput or normal vsynced display FPS. Dear ImGui's embedded loader is disabled; both renderers use GLEW. The viewer has been exercised through automated smoke checks; native file-dialog use and physical mouse gestures have not been manually tested.

Scope: this is a classical-feature course baseline on one controlled industrial dataset. It does not establish production robustness, calibrated confidence, physical defect dimensions, or independent video performance. Candidate localization can miss subtle defects and detect ordinary texture. Held-out results, including failures, must be interpreted separately from visualization quality.

## Sources and licence

KolektorSDD2 is licensed [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/); commercial use requires contacting the dataset owners. Cite **Jakob Božič, Domen Tabernik and Danijel Skočaj (2021), [“Mixed supervision for surface-defect detection: from weakly to fully supervised learning,” Computers in Industry](https://prints.vicos.si/publications/385)**, as requested by the [dataset authors](https://www.vicos.si/resources/kolektorsdd2/).

Dependencies: [OpenCV](https://opencv.org/) (Apache 2.0), [GLFW](https://www.glfw.org/) (zlib/libpng), [GLEW](https://glew.sourceforge.net/) (BSD/MIT components), [Dear ImGui](https://github.com/ocornut/imgui/tree/v1.91.9b) (MIT), and [MSYS2](https://www.msys2.org/) package distributions. Their included licences remain in `.deps/`. No dataset ownership or undocumented team contribution history is claimed.
