# MKMapView API Documentation

**Source**: https://sosumi.ai/documentation/mapkit/mkmapview
**Fetched**: 2025-11-02

## Overview

MKMapView is an embeddable map interface available across iOS 3.0+, iPadOS 3.0+, Mac Catalyst 13.1+, macOS 10.9+, tvOS 9.2+, and visionOS 1.0+. It provides functionality similar to the native Maps application, enabling developers to display and manipulate map content programmatically.

**Core Definition:**
> "An embeddable map interface, similar to the one that the Maps app provides."

The class operates as a `@MainActor` component and should not be subclassed directly.

## Map Display Configuration

### Map Types and Appearance

MKMapView supports multiple presentation styles:

- **MKStandardMapConfiguration**: Default street map showing roads and road names with 2D/3D options
- **MKHybridMapConfiguration**: Satellite imagery with road overlays
- **MKImageryMapConfiguration**: Imagery-based presentations using satellite data

**Key Properties:**
- `preferredConfiguration`: Specifies map characteristics and displayed features
- `mapType`: Defines the data type the map displays
- `camera`: Determines viewing parameters and map appearance

### Map Region and Zoom Control

Regions are defined by a center point and span (horizontal/vertical distance). The span controls zoom level—larger spans show wider areas at lower zoom, while smaller spans display narrow areas at higher zoom.

**Navigation Properties:**
- `region`: The visible area the map displays
- `setRegion(_:animated:)`: Modifies visible region with optional animation
- `centerCoordinate`: Map coordinate at the map's center
- `setCenter(_:animated:)`: Changes center point with optional animation
- `visibleMapRect`: The currently visible area in projected coordinates

### Constraining Map Movement

- `setCameraBoundary(_:animated:)`: Restricts the area where the map center can move
- `cameraBoundary`: Defines boundary constraints
- `setCameraZoomRange(_:animated:)`: Sets zoom level limitations
- `cameraZoomRange`: Specifies minimum and maximum zoom distances

## User Interaction Properties

**Gesture Support:**
- `isScrollEnabled`: Allows user panning (enabled by default)
- `isZoomEnabled`: Allows pinch-to-zoom gestures (enabled by default)
- `isPitchEnabled`: Enables camera pitch functionality
- `isRotateEnabled`: Enables camera heading/rotation

The map supports standard gestures including flick scrolling and pinch zooming out of the box.

## Display Options

**Navigation Controls:**
- `showsCompass`: Displays compass control
- `showsZoomControls`: Shows zoom buttons
- `showsPitchControl`: Reveals pitch adjustment controls
- `showsScale`: Displays scale information
- `pitchButtonVisibility`: Controls pitch button visibility
- `showsUserTrackingButton`: Shows user tracking button

**Map Content:**
- `showsUserLocation`: Attempts to display user's current location
- `isUserLocationVisible`: Indicates if user location appears onscreen
- `userLocation`: The annotation representing user position
- `showsBuildings`: Displays extruded building data on compatible map types
- `showsPointsOfInterest`: Shows POI information
- `pointOfInterestFilter`: Filters which POIs appear
- `showsTraffic`: Displays traffic conditions

## User Location Tracking

- `userTrackingMode`: Controls location tracking behavior
- `setUserTrackingMode(_:animated:)`: Updates tracking mode with optional animation

## Annotation System

### Working with Annotations

Annotations consist of two components:

1. **Annotation Objects**: Conform to `MKAnnotation` protocol; represent data
2. **Annotation Views**: Instances of `MKAnnotationView` or subclasses; handle presentation

**Management Methods:**
- `annotations`: Returns all associated annotations
- `addAnnotation(_:)`: Adds single annotation
- `addAnnotations(_:)`: Adds multiple annotations
- `removeAnnotation(_:)`: Removes specific annotation
- `removeAnnotations(_:)`: Removes multiple annotations
- `annotations(in:)`: Retrieves annotations within a map rectangle

### Selection Management

- `selectedAnnotations`: Currently selected annotations
- `selectAnnotation(_:animated:)`: Selects annotation and shows callout
- `deselectAnnotation(_:animated:)`: Hides annotation callout
- `showAnnotations(_:animated:)`: Adjusts visible region to display specified annotations

### Creating and Reusing Annotation Views

- `register(_:forAnnotationViewWithReuseIdentifier:)`: Registers view class for automatic creation
- `dequeueReusableAnnotationView(withIdentifier:)`: Returns reusable view instance
- `dequeueReusableAnnotationView(withIdentifier:for:)`: Returns reusable view with specified annotation
- `view(for:)`: Returns view associated with annotation object

**Default Identifiers:**
- `MKMapViewDefaultAnnotationViewReuseIdentifier`: Standard annotation views
- `MKMapViewDefaultClusterAnnotationViewReuseIdentifier`: Clustered annotations

## Overlay System

### Overlay Management

Overlays layer content over map regions. Objects conform to `MKOverlay` protocol; renderers handle presentation.

**Addition Methods:**
- `addOverlay(_:)`: Adds single overlay
- `addOverlays(_:)`: Adds multiple overlays
- `addOverlay(_:level:)`: Adds overlay at specified level
- `addOverlays(_:level:)`: Adds multiple overlays at level

**Insertion Methods:**
- `insertOverlay(_:at:)`: Inserts overlay at index
- `insertOverlay(_:at:level:)`: Inserts at index within level
- `insertOverlay(_:above:)`: Places above another overlay
- `insertOverlay(_:below:)`: Places below another overlay

**Overlay Operations:**
- `overlays`: All associated overlays
- `overlays(in:)`: Overlays within specified level
- `renderer(for:)`: Returns renderer for overlay
- `view(for:)`: Returns view for overlay
- `removeOverlay(_:)`: Removes single overlay
- `removeOverlays(_:)`: Removes multiple overlays
- `exchangeOverlay(_:with:)`: Swaps overlay positions

## Coordinate Conversion

Convert between map coordinates and view points:

- `convert(_:toPointTo:)`: Maps coordinate to point in specified view
- `convert(_:toCoordinateFrom:)`: Point to map coordinate conversion
- `convert(_:toRectTo:)`: Map region to rectangle conversion
- `convert(_:toRegionFrom:)`: Rectangle to map region conversion

## Region and Rectangle Adjustment

- `regionThatFits(_:)`: Adjusts region aspect ratio to fit map frame
- `mapRectThatFits(_:)`: Returns centered rectangle matching frame aspect
- `mapRectThatFits(_:edgePadding:)`: Inset rectangle with edge padding

## Points of Interest (iOS 16+, macOS 13+)

Configure POI interactions through `MKMapConfiguration` subclasses with `MKMapFeatureOptions`. Use `MKPointOfInterestFilter` to refine specific POI categories.

Delegate receives interaction callbacks through `MKMapViewDelegate` methods when users select/deselect POIs.

## Look Around Integration (iOS 16+, macOS 13+)

Request street-level views via `MKLookAroundSceneRequest` with map items or coordinates. Display results using `MKLookAroundViewController`.

## Delegate Pattern

Implement `MKMapViewDelegate` protocol to receive map-related updates and coordinate display of custom content. Access delegate via the `delegate` property.

**Important Note:**
> "Don't subclass the `MKMapView` class itself."

## Important Usage Patterns

- Add all annotation objects immediately; the map uses coordinate data to determine display timing
- Annotation views employ reuse queuing for memory efficiency
- Overlay objects can be added anytime; positioning uses overlay level constants
- Appearance customization in macOS 10.14+ uses `NSAppearanceCustomization`

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*
