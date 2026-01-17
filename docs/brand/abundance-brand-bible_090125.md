# **Abundance in the Age of Liquid Glass: A Strategic Brand and Design System for iOS 26**

## **Part I: Strategic Foundation \- Fusing Retro-Futurism with Liquid Glass**

The introduction of Apple's "Liquid Glass" design language with iOS 26, iPadOS 26, and macOS 26 represents the most significant shift in the platform's visual identity since the move to flat design.1 For the Abundance application, whose brand is rooted in a distinct retro-futuristic vaporwave aesthetic, this transition presents both a challenge and a profound opportunity. The core of the Abundance visual identity is defined by high-gloss surfaces, chrome accents, and a specific 1980s advertising mood—elements that appear, at first glance, antithetical to a system built on translucency and light.3

This document outlines a strategic evolution of the Abundance brand, not a replacement. It provides a comprehensive framework for fusing the app's unique character with the principles of Liquid Glass, ensuring the result is an experience that is both authentically Abundance and deeply native to the next generation of Apple's operating systems. The following principles establish the foundation for this synthesis, translating the brand's core DNA into the new language of refractive glass, dynamic vibrancy, and fluid motion.

### **1.1 Principle 1: From Opaque Gloss to Refractive Glass**

The foundational challenge is to reconcile Abundance's material palette—high-gloss finishes and chrome—with the translucent nature of Liquid Glass. The solution lies in reinterpreting these materials not as opaque surface treatments but as properties of the glass itself. This approach treats the application's UI components as physically crafted objects made from this new digital material, allowing the brand's retro-futurism to manifest through the physics of light, depth, and refraction.

This strategic alignment leverages a key aspect of the Liquid Glass paradigm: its return to a more sophisticated form of skeuomorphism. While early iOS design mimicked literal objects like felt and leather, Liquid Glass draws its inspiration from the physical properties of glass and water, creating translucent overlays that refract the light of elements beneath them.2 Abundance's existing brand, with its reference to real-world 1980s materials, is already implicitly skeuomorphic. The convergence of these two philosophies provides a unique opportunity for synthesis. Instead of a conflict between opaque and transparent styles, the app can embrace this new skeuomorphism, leading to a design system that feels physically grounded and native to iOS 26, embodying the "familiar wonder" that defines the Apple user experience.2

**Translating "High-Gloss" to Multi-Layered Depth**

The "high-gloss surfaces" specified in the brand DNA will evolve into multi-layered Liquid Glass panes.3 This directly employs a core tenet of glassmorphism: the use of a multi-layered, floating approach to establish a sense of depth and visual hierarchy.4 In practice, this will be achieved by stacking SwiftUI views and applying different

Material thicknesses, such as placing a view with a .thinMaterial background over one with a .regularMaterial background. This creates a subtle parallax effect as the user scrolls, enhancing the perception of three-dimensional space.6 The glossiness is no longer a simple reflection on a flat surface but a product of light interacting with multiple layers of translucent material.

**Translating "Chrome Accents" to Refractive Edges**

The "chrome accents" that define much of the brand's premium feel will be redefined as a visual effect applied to the _edges_ of Liquid Glass components.3 Rather than a flat metallic texture, "chrome" will be characterized by high-contrast specular highlights, subtle inner shadows, and a pronounced refractive quality that bends the light from the content behind it, mimicking the look of polished metal. This aligns perfectly with the described capabilities of Liquid Glass, which is designed to reflect and refract its surroundings.8 This effect can be prototyped using layered effects in design tools like Figma and ultimately implemented in SwiftUI using custom

ShapeStyle definitions, potentially augmented with Metal shaders for maximum fidelity.9

**Translating "Terrazzo Textures" to Environmental Backgrounds**

The distinctive terrazzo pattern will be used more sparingly, serving primarily as a background element visible _through_ the main UI layers.3 This follows a key principle of effective glassmorphism: the effect is most pronounced when placed over a vibrant, colorful, or textured background, as the pattern peeking through the blur accentuates the frosted-glass aesthetic.5 In Abundance, the terrazzo will provide a textural anchor for the entire experience, grounding the floating glass elements and reinforcing the 1980s retro style without overwhelming the interface.

To ensure clarity and consistency in this translation, the following matrix provides a clear reference for designers and developers.

**Table 1: Brand DNA to Liquid Glass Translation Matrix**

| Original Brand Attribute         | iOS 26 Interpretation                        | Key Visual Characteristics                                                                                                   | Primary Implementation Method                                                                                             |
| :------------------------------- | :------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------ |
| **High-Gloss Surfaces**          | Multi-Layered Glass Panes                    | Parallax scrolling effect, varying levels of blur and translucency, subtle depth cues.                                       | Stacked SwiftUI views with different Material thicknesses (e.g., .thin, .regular).6                                       |
| **Chrome Accents**               | Refractive Glass Edge Effect                 | Pronounced specular highlights, light refraction, subtle inner shadow to mimic polished metal.                               | Custom SwiftUI ShapeStyle with a 1px border and inner shadow; potentially a Metal shader for advanced refraction.10       |
| **Terrazzo Textures**            | Background Environmental Texture             | Visible through translucent UI layers, provides textural depth and reinforces retro theme.                                   | Used as a background image or pattern behind the main content view, blurred by overlying materials.                       |
| **Strong Directional Lighting**  | Dynamic Specular Highlights & Internal Glows | Light sources appear to interact with glass surfaces, creating reflections and refractions that shift with user interaction. | Achieved through the inherent properties of Liquid Glass and custom lighting effects within 3D rendered assets.2          |
| **\#4381DF Blue Neon Underglow** | Vibrancy-Aware Internal Lighting             | Color is used as a light source within components, with its appearance adapting based on the background.                     | foregroundStyle modifier with brand colors on text/icons; color fills within components that glow through the material.13 |

### **1.2 Principle 2: The Vaporwave Palette in a Dynamic, Vibrant Environment**

The Abundance color palette—comprising bright blue, coral orange, salmon pink, cream yellow, and mint green—is a cornerstone of its brand identity.3 In the Liquid Glass environment, these colors must be deployed thoughtfully to work with, not against, the principles of translucency and dynamic adaptation.

**Vibrancy and Legibility**

Apple's Human Interface Guidelines (HIG) for materials are explicit: to ensure legibility, vibrant colors should be used for foreground content placed on top of a material.15 The translucency and blur of Liquid Glass can otherwise cause text and icons to wash out against the background. Abundance will adhere to this by using SwiftUI's

foregroundStyle modifier to apply vibrancy effects. The brand's colors will be used to create distinct levels of vibrancy:

- **Primary Vibrancy:** The most saturated versions of the brand colors will be used for primary text and interactive icons, ensuring they meet or exceed WCAG 2.2 contrast ratios of 4.5:1 for normal text and 3:1 for large text.11
- **Secondary/Tertiary Vibrancy:** Muted or less saturated versions will be applied to supplementary information, captions, and disabled states, maintaining a clear visual hierarchy while still feeling integrated with the overall design.14

**Color as a Source of Light**

The brand's vibrant accent colors will be used not just as static fills but as dynamic sources of _light_. This concept is already present in the original design prompts, such as the glowing blue interior of the app icon or the accent lighting in category cards.3 In the iOS 26 implementation, this will be taken further. For example, the coral orange accent lighting in the "Kitchen" category card will not just color the scene; it will appear to emanate from within the 3D-rendered objects, with its light realistically refracting and reflecting off the Liquid Glass layers of the card's UI. This transforms color from a decorative element into an active, physical property of the interface.

**Tints and Personalization**

iOS 26 and iPadOS 26 introduce new personalization options, including colorful light and dark tints that users can apply to app icons and system elements.16 Abundance will embrace this feature by offering its core brand colors—specifically the bright blue (\#4381DF) and coral orange (\#FF9A6F)—as selectable app-wide tints. This allows users to personalize their experience while remaining firmly within the Abundance brand world. This also proactively addresses potential community feedback that the default clear look of Liquid Glass icons can sometimes lack distinctiveness and contrast on certain wallpapers.17

### **1.3 Principle 3: Playful & Approachable through Fluid Motion**

The "playful, stylish, premium, and approachable" mood of the Abundance brand will be communicated primarily through a sophisticated and fluid motion language.3 The "Liquid" aspect of the new design system provides the perfect canvas for bringing this personality to life.

**Responsive and Tactile Interactions**

Liquid Glass is described as a material that responds dynamically to user interaction.18 This principle will be applied to all interactive elements in Abundance. Buttons and controls will not merely change color when pressed; they will provide tactile feedback by appearing to depress into the Z-axis. This will be achieved through a combination of subtle animations: the material of the button will become slightly more opaque, its scale will decrease marginally, and the surrounding light will refract differently, reinforcing the sensation of interacting with a physical, glass-like object.19 This level of responsiveness elevates the experience from a series of taps to a tangible interaction.

**Motion as Brand Reinforcement**

The motion language will be designed to directly reinforce the brand's core mood attributes:

- **Playful:** Expressed through bouncy, spring-like animations when new items are successfully scanned and added to the catalog.
- **Stylish & Premium:** Conveyed through smooth, 60fps transitions with custom easing curves that feel polished and sophisticated. The subtle refractive shifts of light across glass surfaces as a user scrolls will contribute to this premium feel.
- **Approachable:** Ensured by creating intuitive, physics-based animations that are predictable and non-jarring. For example, when a modal sheet is dismissed, it will shrink back to its point of origin, visually reinforcing the app's spatial model.

**Accessibility as a Prerequisite**

The reliance of glassmorphism on motion and blur effects poses significant accessibility challenges for users with vestibular disorders or visual impairments.11 Therefore, an accessibility-first approach to motion design is non-negotiable.

- **Reduced Motion:** The application must fully respect the prefers-reduced-motion system setting. When this is enabled, all complex, physics-based animations will be replaced with simple, non-jarring cross-fade transitions.11
- **Reduced Transparency:** The app must also fully support the Reduce Transparency accessibility setting. When enabled, all translucent Liquid Glass materials will be replaced with opaque or semi-opaque backgrounds derived from the brand's color palette. This ensures that high contrast and legibility are maintained for all users, regardless of their system settings.11

By defining a motion language that is both expressive and inclusive, Abundance can leverage the dynamism of Liquid Glass to communicate its brand personality more effectively than ever before.

## **Part II: The Abundance Design System for iOS 26**

This section provides the granular, component-level specifications for the entire Abundance user interface. It translates the strategic principles from Part I into an actionable design system, forming a definitive guide for the design and development teams to build a consistent, polished, and platform-native application for iOS 26\.

### **2.1 Shape, Layout, and Concentricity: The Geometric Foundation**

The WWDC 2025 keynote introducing Liquid Glass placed heavy emphasis on a new "quiet geometry" that governs the shape and layout of UI elements.19 This system, built on principles of concentricity and a defined set of shape types, creates a harmonious rhythm between the physical hardware and the on-screen interface. Abundance will adopt this geometric foundation system-wide to ensure it feels deeply integrated with the OS.

**Adoption of System Shape Types**

The application will utilize the three primary shape types defined for concentric layouts 19:

- **Capsules for Controls:** Large, primary action buttons (e.g., "Start Scanning"), sliders, toggles, and other interactive controls will adopt the capsule shape. A capsule's corner radius is exactly half its height, creating a form that is both visually distinct and highly touch-friendly. This shape brings focus and clarity to the most important actions in the layout.19
- **Concentric Shapes for Containers:** All container elements—including item cards, category cards, widgets, and grouped list views—will use concentric shapes. These shapes calculate their corner radius by subtracting a padding value from the radius of their parent container. This mathematical relationship ensures that nested elements align perfectly, creating visual harmony and a sense of order.19 This principle will be directly applied to the redesign of the
  Item Card Template and Category Cards from the original brand document.3
- **Fixed Shapes:** Where a constant corner radius is required for specific design elements that do not need to adapt to a parent container, fixed-radius rectangles will be used, though capsules and concentric shapes will be the default for most components.

**Layout, Spacing, and Structural Elements**

In line with the broader iOS 26 redesign, the Abundance layout will be updated to be more spacious and less cluttered.8

- **Increased Padding:** Spacing and padding around elements will be increased to improve legibility and create a more breathable layout.
- **Inset Sidebars:** On iPadOS and macOS, the main catalog view will feature an inset sidebar. This sidebar will be constructed with Liquid Glass, allowing background content to flow behind it and creating a more immersive, layered experience.19
- **Floating Navigation:** The primary navigation will be presented in a floating tab bar that sits above the content, a signature element of the new design language.21

### **2.2 Iconography: Multi-Layered, Refractive Glass Objects**

The original brand prompts call for "3D rendered" icons, a concept that will be evolved to align with the new possibilities of iOS 26\.3 Icons are no longer static, flat images but dynamic, multi-layered objects that react to light and motion.8 The Abundance iconography will be redesigned as if each icon is a miniature object meticulously crafted from Liquid Glass.

**The App Icon: A Dynamic Microcosm**

The main app icon serves as the primary entry point to the Abundance experience and must perfectly encapsulate the new brand identity. It will be redesigned using Apple's new Icon Composer tool, which is specifically built to create these new-style icons with features for annotating layers, adjusting translucency, and testing specular highlights.22

- **Evolution of Concept:** The original concept of a miniature display case will be retained but re-imagined as a multi-layered glass object.3 The tiny floating icons representing inventory items will appear suspended at different depths within the glass cube.
- Light and Refraction: The glowing \#4381DF blue interior will now act as an internal light source, illuminating the icon from within and casting subtle caustics. The "chrome trim" will be transformed into a highly refractive edge with dynamic specular highlights that shift as the user tilts their device.
  The app icon thus becomes a perfect microcosm of the in-app experience, communicating the principles of layered glass, internal lighting, and refractive materials before the user even launches the application.

**Navigation and In-App Icons**

The set of five primary navigation icons (Scan, Catalog, Share, Trade, Profile) will be redesigned to match this new paradigm.3

- **Shape and Material:** They will be minimalist, capsule-shaped glass objects, replacing the previous "chrome finish" with a clear, refractive glass appearance.
- **Color Accents:** The brand color accents (\#4381DF, \#FF9A6F, etc.) will be applied not as flat fills but as internal glows or through the dynamic vibrancy effect of the foregroundStyle when the icon is active. This ensures the color feels like an intrinsic property of the icon rather than a simple overlay.

### **2.3 Typography and Legibility**

The iOS 26 update includes refinements to system typography designed to enhance clarity and structure.19 The Abundance typographic scale will be updated to align with these new standards.

- **Bolder and Left-Aligned:** Headings and key interface text will be made bolder and more consistently left-aligned, particularly in critical views like alerts, onboarding screens, and permission requests. This improves scannability and establishes a stronger visual hierarchy.
- **Contrast is Non-Negotiable:** The single most critical consideration for typography on a translucent background is legibility. All text throughout the application must meet or exceed the Web Content Accessibility Guidelines (WCAG) 2.2 contrast ratios: a minimum of 4.5:1 for body text and 3:1 for large or bold UI components.11 This will be rigorously enforced through the systematic application of material thickness and vibrancy, as detailed in the following section. Where necessary, such as text overlaid on a user-provided image, a semi-opaque fill will be placed behind the text to ensure it remains readable against a potentially busy background.12

### **2.4 The Material & Vibrancy Matrix**

To eliminate ambiguity and ensure a consistent, predictable application of Liquid Glass effects, this section provides a definitive matrix for mapping material properties to UI components and their states. This systematic approach ensures that the use of translucency and vibrancy supports, rather than detracts from, the application's information hierarchy.

**Mapping Material Thickness to Function**

Specific SwiftUI Material thicknesses will be mapped to distinct UI element categories to create a clear visual language 6:

- **.ultraThinMaterial & .thinMaterial:** Reserved for transient, contextual elements like pop-out menus or temporary overlays where maintaining a strong visual connection to the content behind them is beneficial.
- **.regularMaterial:** The default choice for persistent, primary surfaces like tab bars and navigation bars. It provides an ideal balance of showing background context while maintaining the clarity of the controls.
- **.thickMaterial & .ultraThickMaterial:** Used for modal sheets, alerts, and other views that demand user focus. The increased opacity obscures the background content, reducing distraction and centering attention on the modal task.

**Mapping Vibrancy Levels to Content**

SwiftUI's foregroundStyle modifier will be used to apply vibrancy levels that correspond to the importance of the content 13:

- **.primary:** For all primary text content and critical, interactive icons.
- **.secondary:** For supplementary information, captions, and placeholder text.
- **.tertiary:** For less important metadata and disabled interface elements.
- **.separator:** For divider lines within lists or menus.

The following matrix codifies these rules into a practical guide for implementation.

**Table 2: Component State & Material Specification Matrix**

| UI Component           | State    | Shape Style | Material Thickness  | Foreground Vibrancy                          | Accent Color Usage                    |
| :--------------------- | :------- | :---------- | :------------------ | :------------------------------------------- | :------------------------------------ |
| **Primary Button**     | Default  | Capsule     | .regularMaterial    | .primary                                     | Tint fill color (e.g., \#4381DF)      |
|                        | Pressed  | Capsule     | .thickMaterial      | .primary                                     | Tint fill color, slightly darker      |
|                        | Disabled | Capsule     | .ultraThickMaterial | .tertiary                                    | Desaturated tint fill                 |
| **Item Card**          | Default  | Concentric  | .thickMaterial      | .primary (Title), .secondary (Desc)          | None (uses vibrancy)                  |
| **Category Card**      | Default  | Concentric  | .thickMaterial      | .primary                                     | Internal glow effect (e.g., \#FF9A6F) |
| **Tab Bar**            | Active   | Capsule     | .regularMaterial    | .primary (selected), .secondary (unselected) | Tint color for selected icon          |
| **Modal Sheet**        | Active   | Concentric  | .ultraThickMaterial | .primary                                     | None                                  |
| **Search Bar**         | Active   | Capsule     | .thinMaterial       | .primary                                     | Glowing blue (\#4381DF) active state  |
| **Permission Request** | Active   | Concentric  | .thickMaterial      | .primary                                     | Accent color on character/icon        |

## **Part III: Redefining the Core User Experience**

With the design system established, this part applies these new principles to the key screens and user flows defined in the original Abundance brand bible.3 Each element is re-imagined to leverage the spatial, dynamic, and intelligent capabilities of iOS 26, transforming the user experience from a series of static screens into an interactive, fluid space.

### **3.1 First Impressions: App Icon, Splash, and Onboarding**

The initial moments of user interaction are critical for establishing the brand's premium and stylish mood. The evolution to Liquid Glass will make this first impression more impactful than ever.

- **App Icon and Splash Screen:** As detailed in Part II, the app icon will be a dynamic, multi-layered glass object created with Apple's Icon Composer.22 The splash screen will feature the "Abundance" logotype, re-rendered not with a "chrome lettering" effect, but as three-dimensional, refractive glass text. This text will appear to float above the stylized terrazzo platform, catching and bending light as the app launches, immediately introducing the user to the core material of the new design language.3
- **Onboarding Flow:** The onboarding screens will serve as a masterclass in the layered, spatial nature of Liquid Glass. The "Welcome Screen Hero" illustration will no longer be a flat 3D graphic but a fully realized spatial composition.3 It will feature a 3D model of a smartphone rendered within a glass
  Volume (a SwiftUI scene for 3D content), with the app's UI cards floating at varying depths in front of and behind it. The background will be a soft, animated gradient, allowing the translucency and refraction of the foreground elements to create a captivating sense of depth and immersion. Typography will be bold and left-aligned, ensuring the welcoming messages are clear and readable, as per the new HIG standards.19

### **3.2 Navigating the Abundance Space: Toolbars, Menus, and Search**

Navigation in iOS 26 is designed to be more contextual and less obtrusive, a principle Abundance will fully embrace.

- **Floating Navigation Bar:** The primary navigation controls will be housed in a floating, pill-shaped tab bar at the bottom of the screen, consistent with the updated design patterns across iOS 26\.8 This bar will use a
  .regularMaterial background, allowing the content of the underlying screen to subtly show through. The icons within will use the brand's accent colors with a primary vibrancy effect when selected, providing clear visual feedback.
- **Contextual "Springing" Menus:** In line with the new HIG, secondary and contextual actions will be moved out of cluttered toolbars and into menus that "spring directly from the action itself".19 For example, tapping and holding on an item card in the catalog will cause a menu of options (e.g., "Edit," "Share," "List for Sale") to emerge directly from the card, anchored to the user's touch point. This makes the interaction feel more direct and spatially logical.
- **Fluid Search Interface:** The search experience will be redesigned for fluidity and focus. The "retro-futuristic search bar" 3 will be replaced by a simple, capsule-shaped glass button containing a search icon, likely integrated into the main navigation bar or header. When tapped, this button will fluidly expand into a full-screen search interface. This search view will use a
  .thinMaterial background, keeping the user oriented within the app. Search suggestions will appear not as a simple list, but as individual, floating glass capsules that animate into view, each containing a suggestion.

### **3.3 The Intelligent Scanner: A Vision-Powered Experience**

The core scanning feature of Abundance is where the application's intelligence will be most apparent. The experience will be enhanced by leveraging the full power of Apple's on-device computer vision frameworks.

- **Viewfinder Overlay Redesign:** The camera viewfinder overlay will be stripped of its hard-edged "chrome corner brackets".3 These will be replaced with soft, glowing glass elements that gently pulse to indicate the scanner is active. The scanning grid will be reimagined as a subtle, animated light effect that plays across the camera feed, providing a futuristic yet unobtrusive visual cue.
- **On-Device Recognition Pipeline:** The scanning process will utilize a pipeline of on-device frameworks to intelligently identify items without sending any user data to the cloud.
  1. **Vision Framework:** The primary analysis will be handled by the Vision framework. The app will initiate multiple requests on each camera frame: a VNRecognizeTextRequest to read any text on the object (such as a brand name, model number, or title) 23; a
     VNDetectBarcodesRequest to identify any QR codes or standard barcodes 23; and a general object classification request using a custom Core ML model (detailed in Part IV) or a built-in classifier to identify the type of object (e.g., "sneaker," "book," "kitchen appliance").26
  2. **New iOS 26 Vision Features:** The scanner will incorporate new capabilities introduced with iOS 26\. Before scanning, it can use the DetectLensSmudgeRequest to check for a dirty camera lens and prompt the user to clean it, improving recognition accuracy.20 If the user is scanning a receipt or warranty card, the
     DetectDocumentSegmentationRequest can be used to isolate the document from its surroundings for more precise text recognition.26
- **Success and Error State Animations:** The "Item Recognition Success" celebration graphic will be a dynamic and satisfying animation. The scanned item will be highlighted with a refractive glass frame, followed by an explosion of glassy, confetti-like particles in the brand's colors that shimmer and fade.3 The "Scanning Error State" will be designed to be approachable and non-threatening. Instead of a static illustration, it will feature a softly pulsating, translucent glass question mark, gently encouraging the user to try again.3

### **3.4 The Living Catalog: Item Cards, Grids, and Empty States**

The user's inventory catalog is the heart of the application. Its design will be updated to feel like a modern, premium, and interactive space.

- **Item and Category Cards:** The Item Card Template and Category Cards will be redesigned as concentric, rounded-corner glass panes, adhering to the new system geometry.3 The content (product image, title, price) will appear on a top layer, while the card itself will be a
  .thickMaterial pane that blurs the background terrazzo texture. The "chrome frame" will be replaced by a subtle, 1-pixel inset border. This border is a critical detail in modern glassmorphism, as it helps to clearly define the element's edge against the blurred background, improving tangibility and accessibility.4
- **Scroll Edge Effects:** As the user scrolls through their grid of item cards, the floating navigation bar at the bottom of the screen will trigger a soft scroll edge effect. This effect creates a subtle blur at the edge of the scroll view, reinforcing the boundary between the scrolling content and the persistent UI without the need for harsh, solid divider lines.19 This makes the interface feel cleaner and more integrated.
- **Welcoming Empty States:** The "Empty State \- New User" illustration will be more dynamic and inviting.3 It will feature a 3D scene of empty, shimmering glass display cases that gently pulse with a soft blue (\#4381DF) light. Floating plus icons, also rendered as glass objects, will drift slowly, inviting the user to tap and initiate their first scan. This transforms the empty state from a passive placeholder into an active, welcoming call to action.

## **Part IV: Advanced Capabilities with On-Device Machine Learning**

This section details a significant expansion of the Abundance application's capabilities, moving beyond the original brand bible's scope to integrate Apple's most advanced on-device machine learning frameworks. By leveraging the Foundation Models framework, Core ML, and other intelligent APIs announced at WWDC 2025, Abundance can transform from a simple inventory utility into a truly intelligent platform that automates tedious tasks, provides expert-level recognition, and delivers dynamic, real-time insights—all while maintaining uncompromising user privacy.

### **4.1 Automated Itemization with the Foundation Models Framework**

The proposed "Intelligent Cataloging" feature represents a paradigm shift for the app's core functionality. After the Vision framework performs its initial analysis of an object, this feature will use Apple's powerful on-device Large Language Model (LLM) to automatically generate a complete, structured, and well-written inventory entry. This eliminates the most tedious part of the user journey: manual data entry.

**Implementation with Guided Generation**

The feature will be implemented using the Foundation Models framework's "Guided Generation" capability, which allows the model to generate structured Swift data types directly, rather than unstructured text.27 The process is as follows:

1. **Define a Generable Struct:** A Swift struct will be defined to represent an inventory item (e.g., CatalogItem). This struct will be marked with the @Generable macro, which makes it recognizable to the Foundation Models framework.29
2. **Provide Natural Language Guides:** The properties within the CatalogItem struct (e.g., title, description, category, estimatedValue) will be annotated with the @Guide macro. This macro provides natural language instructions to the model, steering its output. For example: @Guide(description: "A concise, marketable title for the item, under 60 characters.") var title: String.
3. **Prompt the On-Device Model:** After the Vision framework extracts raw data (e.g., object type: 'sneaker', recognized text: 'Nike Air Max 90'), the app will create a LanguageModelSession and pass a prompt to the on-device model. The prompt will be simple and direct: "Based on the following recognized data, generate a CatalogItem: {object: 'sneaker', text: 'Nike Air Max 90'}".31
4. **Receive a Type-Safe Object:** The Foundation Models framework handles the complex task of interpreting the prompt, constraining the LLM's output to the schema of the CatalogItem struct, and populating its properties. The framework then returns a fully formed, type-safe CatalogItem instance directly to the app.30 This object can then be presented to the user for confirmation and immediately saved to their inventory.

**Privacy, Performance, and Feature Tiering**

This entire process occurs exclusively on the user's device, leveraging the power of Apple Intelligence.31 This provides three immense strategic advantages:

- **Privacy:** It is a powerful selling point that no images of the user's personal belongings or any associated data are ever sent to a cloud server for processing. This aligns perfectly with the "premium" and "trustworthy" pillars of the brand.27
- **Performance:** On-device processing means the feature is incredibly fast and responsive. It works offline, without any network latency, making the app reliable anywhere.31
- **Feature Segmentation:** Apple has stated that Apple Intelligence features, including the Foundation Models framework, require an iPhone 15 Pro or newer due to the demands on the Neural Engine.35 This creates a natural and compelling feature segmentation for Abundance. All users can add items manually. Users with older, compatible iPhones can use the standard Vision-powered scanning for basic text and object recognition. However, users with the latest hardware will unlock the full, magical "Intelligent Cataloging" experience. This can be marketed as a premium feature and provides a clear strategic path for a future "Abundance Pro" subscription tier without fragmenting the core experience for the existing user base.

### **4.2 Precision Recognition with Custom Core ML Models**

While the general-purpose Vision and Foundation Model frameworks are incredibly powerful, certain niche or high-value item categories (e.g., specific models of collectible sneakers, designer handbags, rare books, or electronic components) may require more specialized recognition capabilities than a general model can provide.

**Core ML for Expert-Level Identification**

To address this, Abundance can integrate custom-trained or publicly available machine learning models using Core ML.

- **Model Conversion and Integration:** The development team can train their own models or source pre-trained models from libraries like TensorFlow or PyTorch. Using Apple's open-source Core ML Tools package, these models can be converted into the optimized .mlmodel format.36 For instance, a
  DETR (DEtection TRansformer) model could be used for highly precise, fine-grained object detection, or a FastViT (Fast Vision Transformer) model could be employed for extremely accurate classification of visually similar items like different sneaker colorways.38
- **On-Device Execution:** Once integrated into the app, Core ML executes these models directly on the device, efficiently leveraging the CPU, GPU, and Neural Engine to ensure maximum performance and minimal power consumption.39 This custom model pipeline can be triggered when the initial scan suggests an item belongs to a "specialist" category, adding a layer of expert-level precision to the recognition process.

### **4.3 Dynamic Valuation and Marketplace Insights**

The "Price Estimation Graphics" from the original brand bible can be transformed from a static display into a living, interactive data visualization powered by on-device intelligence.3

**Data Visualization with Liquid Glass**

Instead of simply showing numbers in chrome frames, price trends and market data will be visualized as fluid, glowing lines or particle systems contained within a Liquid Glass volume. The material of this container could subtly refract and distort based on the data's volatility, creating a data visualization that is not only informative but also aesthetically aligned with the app's core design language.

**Tool Calling for Real-Time Data**

To provide accurate, up-to-the-minute market data, the app will use the Foundation Models framework's "Tool Calling" capability.27 When a user asks a question like, "What is this sneaker worth today?", the on-device LLM can recognize the need for external information. It will then execute a predefined "tool"—a secure function within the app that makes an API call to Abundance's backend or a third-party market data provider. The live data is then fed back to the on-device model, which formulates a comprehensive, natural language response for the user (e.g., "Based on recent sales, this model is trending up. Similar pairs in this condition are selling for between $250 and $280.").29 This creates a powerful, conversational interface for accessing real-time data.

To provide a clear technical blueprint for the engineering team, the following matrix maps these advanced features to the specific Apple frameworks and APIs required for their implementation.

**Table 3: On-Device Technology Integration Matrix**

| Feature                        | Primary Framework | Specific API/Request                                     | Secondary Framework(s) | Required iOS / Hardware                                    |
| :----------------------------- | :---------------- | :------------------------------------------------------- | :--------------------- | :--------------------------------------------------------- |
| **Intelligent Cataloging**     | Foundation Models | LanguageModelSession, @Generable struct, @Guide macro 28 | Vision                 | iOS 26 with Apple Intelligence (iPhone 15 Pro or newer) 35 |
| **Precision Item Recognition** | Core ML           | MLModel class, Core ML Tools for conversion 36           | Vision                 | iOS 26                                                     |
| **Lens Smudge Detection**      | Vision            | DetectLensSmudgeRequest 20                               | \-                     | iOS 26                                                     |
| **Live Market Valuation**      | Foundation Models | Tool protocol for API calls (Tool Calling) 27            | \-                     | iOS 26 with Apple Intelligence (iPhone 15 Pro or newer) 35 |
| **Basic Object Scanning**      | Vision            | VNRecognizeTextRequest, VNDetectBarcodesRequest 23       | \-                     | iOS 26                                                     |
| **Document Scanning**          | Vision            | DetectDocumentSegmentationRequest 26                     | \-                     | iOS 26                                                     |

## **Part V: Implementation and Accessibility**

This final section provides critical, non-negotiable guidelines to ensure the Abundance application is not only visually stunning and technologically advanced but also robust, inclusive, and buildable. It addresses the practical challenges of implementing a glassmorphism-based design and outlines a clear path for development.

### **5.1 A Non-Negotiable Approach to Accessibility**

The aesthetic appeal of Liquid Glass cannot come at the cost of usability. Translucent, multi-layered interfaces, often referred to as glassmorphism, present inherent accessibility challenges, primarily related to low contrast and potentially disorienting motion effects.11 Abundance will adopt a proactive, accessibility-first stance to mitigate these issues, ensuring the app is usable and comfortable for everyone.

**Mandatory Support for System Accessibility Settings**

The application's design must be fully adaptive and responsive to the user's system-wide accessibility preferences. This is not an optional feature but a core requirement for a high-quality iOS application.

- **Reduce Transparency:** The app _must_ listen for and immediately respond to the Reduce Transparency setting found in Settings \> Accessibility \> Display & Text Size.20 When a user enables this toggle, all translucent Liquid Glass materials throughout the app will be programmatically replaced with solid or near-opaque color fills derived from the brand's palette. This will guarantee high-contrast, legible interfaces for users who find transparency difficult to read.11
- **prefers-reduced-motion:** The app _must_ respect the prefers-reduced-motion media query. When this setting is enabled, all complex, physics-based animations (such as the bouncy, spring-like effects or fluid transitions) will be replaced with simple, non-jarring cross-fade animations. This is essential for users with vestibular sensitivities who can experience nausea or dizziness from excessive motion.11

**Designing for Contrast and Clarity by Default**

Even in its default, full-featured state, the design must prioritize clarity.

- **WCAG 2.2 Compliance:** All combinations of text, icons, and their backgrounds must pass WCAG 2.2 contrast ratio requirements (4.5:1 for normal text, 3:1 for large text).11 This will be achieved through the careful pairing of
  Material thickness and foregroundStyle vibrancy, as specified in the matrix in Part II.
- **Reinforcing Hierarchy:** To prevent UI elements from becoming lost against the blurred background, subtle visual cues will be used to reinforce the information hierarchy. As specified in the design system, all glass panes (like item cards) will include a subtle, 1-pixel inset border or a soft drop shadow. These small details significantly improve the tangibility of the elements, helping to define their edges and separate them from the content underneath.12

**Mandatory Testing with Assistive Technologies**

Design mockups can be deceptive. What appears elegant in Figma may break down when used with assistive technologies. Therefore, the development and QA process must include rigorous testing with real users and standard accessibility tools, including:

- **VoiceOver:** To ensure the UI hierarchy is logical, all elements are correctly labeled, and the app is fully navigable without sight.
- **Contrast Checkers:** To programmatically verify that all interface states meet contrast requirements.
- **User Testing:** With individuals who have varying levels of visual acuity and motion sensitivity to gather real-world feedback on the design's usability.

### **5.2 Developer Guide: SwiftUI Implementation Blueprints**

This section provides high-level conceptual guidance and code patterns for the engineering team to begin implementing the Abundance design system in SwiftUI.

**Building Components with Materials and Shapes**

The core of the visual design will be implemented using SwiftUI's powerful view modifiers.

- **Applying Materials:** The .background() modifier is the primary tool for applying materials. The implementation will involve layering views and applying different Material types to achieve the desired depth and translucency. For example, a basic glass card would be constructed as follows 6:
  Swift
  Text("Item Title")
  .font(.headline)
  .foregroundStyle(.primary) // Applies primary vibrancy
  .padding()
  .frame(maxWidth:.infinity, alignment:.leading)
  .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 20, style:.continuous)) // Applies material in a specific shape
  .overlay(
  RoundedRectangle(cornerRadius: 20, style:.continuous)
  .stroke(Color.white.opacity(0.2), lineWidth: 1) // Adds subtle border for definition
  )

- **Using System Shapes:** The new capsule and concentric shape styles will be used extensively. For a primary action button, the implementation would leverage the Capsule shape directly 19:
  Swift
  Button("Start Scanning") {
  // Action
  }

.buttonStyle(.borderedProminent)
.controlSize(.large)
.tint(Color(hex: "\#4381DF")) // Brand's blue color
.clipShape(Capsule())
\`\`\`
**Managing Performance**

While SwiftUI and the Metal graphics pipeline are highly optimized, an excessive number of blurred, translucent layers can still impact performance, especially on older devices that support iOS 26\. The development team should:

- **Profile Extensively:** Use Xcode's Instruments to profile the app's performance, paying close attention to GPU usage and frame rates during scrolling and complex animations.
- **Use Materials Judiciously:** Avoid deep stacks of multiple materials where a single, thicker material would suffice.
- **Test on Target Hardware:** Performance must be validated on the full range of supported devices, not just the latest models.

**Framework Integration Path**

Integrating the on-device ML frameworks is a multi-step process. The high-level workflow is:

1. **Vision:** Create a VNImageRequestHandler for a given image (or CVPixelBuffer from the camera feed). Create one or more VNRequest objects (e.g., VNRecognizeTextRequest). Perform the requests and process the resulting VNObservation objects in a completion handler or async function.24
2. **Core ML:** Add the .mlmodel file to the Xcode project. Xcode will automatically generate a Swift interface for it. Instantiate the model class and call its prediction(input:) method to get results.36
3. **Foundation Models:** Import the FoundationModels framework. Check for model availability. Create a LanguageModelSession and use its generate() method, passing a prompt and, for guided generation, specifying the as: type (e.g., CatalogItem.self).28

**Platform Consistency**

The entire design system is built with SwiftUI, which is inherently cross-platform. By structuring the UI with scalable components and a shared anatomy, the Abundance experience will adapt seamlessly across iOS, iPadOS, and macOS, leveraging the unified design language of the "26" OS family.1 This approach minimizes redundant development effort and ensures a consistent, high-quality brand experience on every device.

#### **Works cited**

1. WWDC 2025: What's New for Apple This Year? | Trend Micro News, accessed June 14, 2025, [https://news.trendmicro.com/2025/06/12/wwdc-2025-apple/](https://news.trendmicro.com/2025/06/12/wwdc-2025-apple/)
2. Apple's new Liquid Glass design puts the spotlight on ... \- TechRadar, accessed June 14, 2025, [https://www.techradar.com/phones/iphone/apples-new-liquid-glass-design-puts-the-spotlight-on-skeuomorphism-for-the-first-time-since-ios-6-and-im-all-for-it](https://www.techradar.com/phones/iphone/apples-new-liquid-glass-design-puts-the-spotlight-on-skeuomorphism-for-the-first-time-since-ios-6-and-im-all-for-it)
3. Abundance.pdf
4. Glassmorphism: The Future of UI Design \- apple pro \- LearnLater, accessed June 14, 2025, [https://learnlater.com/summary/apple-pro/8794](https://learnlater.com/summary/apple-pro/8794)
5. What is Glassmorphism? UI Design Trend 2025, accessed June 14, 2025, [https://www.designstudiouiux.com/blog/what-is-glassmorphism-ui-trend/](https://www.designstudiouiux.com/blog/what-is-glassmorphism-ui-trend/)
6. Material | Apple Developer Documentation, accessed June 14, 2025, [https://developer.apple.com/documentation/swiftui/material](https://developer.apple.com/documentation/swiftui/material)
7. Blur effect and materials in SwiftUI | Swift with Majid, accessed June 14, 2025, [https://swiftwithmajid.com/2021/10/28/blur-effect-and-materials-in-swiftui/](https://swiftwithmajid.com/2021/10/28/blur-effect-and-materials-in-swiftui/)
8. iOS 26: Everything We Know | MacRumors, accessed June 14, 2025, [https://www.macrumors.com/roundup/ios-26/](https://www.macrumors.com/roundup/ios-26/)
9. Apple's UI Trend Liquid Glass Comes to Figma: No More Plugins Needed \- Malik Muzamil, accessed June 14, 2025, [https://muzamildzn.framer.website/blogs/apple-s-ui-trend-liquid-glass-comes-to-figma-no-more-plugins-needed](https://muzamildzn.framer.website/blogs/apple-s-ui-trend-liquid-glass-comes-to-figma-no-more-plugins-needed)
10. Create custom visual effects with SwiftUI \- WWDC24 \- Videos \- Apple Developer, accessed June 14, 2025, [https://developer.apple.com/videos/play/wwdc2024/10151/](https://developer.apple.com/videos/play/wwdc2024/10151/)
11. Glassmorphism Meets Accessibility: Can Glass Be Inclusive? | Axess Lab, accessed June 14, 2025, [https://axesslab.com/glassmorphism-meets-accessibility-can-frosted-glass-be-inclusive/](https://axesslab.com/glassmorphism-meets-accessibility-can-frosted-glass-be-inclusive/)
12. What Is Glassmorphism? | IxDF \- The Interaction Design Foundation, accessed June 14, 2025, [https://www.interaction-design.org/literature/topics/glassmorphism](https://www.interaction-design.org/literature/topics/glassmorphism)
13. Using Apple's Materials Blur & Vibrancy in Your App Design \- Play \- CreateWithPlay.com, accessed June 14, 2025, [https://createwithplay.com/blog/best-practices-for-using-materials-properties](https://createwithplay.com/blog/best-practices-for-using-materials-properties)
14. Using materials with SwiftUI \- Create with Swift, accessed June 14, 2025, [https://www.createwithswift.com/using-materials-with-swiftui/](https://www.createwithswift.com/using-materials-with-swiftui/)
15. Materials | Apple Developer Documentation, accessed June 14, 2025, [https://developer.apple.com/design/human-interface-guidelines/materials](https://developer.apple.com/design/human-interface-guidelines/materials)
16. iPadOS 26 introduces powerful new features that push iPad even further \- Apple, accessed June 14, 2025, [https://www.apple.com/newsroom/2025/06/ipados-26-introduces-powerful-new-features-that-push-ipad-even-further/](https://www.apple.com/newsroom/2025/06/ipados-26-introduces-powerful-new-features-that-push-ipad-even-further/)
17. Details of Liquid Glass UI/UX : r/apple \- Reddit, accessed June 14, 2025, [https://www.reddit.com/r/apple/comments/1l7iwkd/details_of_liquid_glass_uiux/](https://www.reddit.com/r/apple/comments/1l7iwkd/details_of_liquid_glass_uiux/)
18. Apple WWDC 2025: A new era of Apple Intelligence, Liquid Glass design, and seamless integration \- Gadget Flow, accessed June 14, 2025, [https://thegadgetflow.com/blog/apple-wwdc-2025-highlights/](https://thegadgetflow.com/blog/apple-wwdc-2025-highlights/)
19. Get to know the new design system \- WWDC25 \- Videos \- Apple ..., accessed June 14, 2025, [https://developer.apple.com/videos/play/wwdc2025/356/](https://developer.apple.com/videos/play/wwdc2025/356/)
20. The 7 hidden iOS 26 features I'm excited to try \- Mashable, accessed June 14, 2025, [https://mashable.com/article/ios-26-hidden-features](https://mashable.com/article/ios-26-hidden-features)
21. Apple elevates the iPhone experience with iOS 26, accessed June 14, 2025, [https://www.apple.com/newsroom/2025/06/apple-elevates-the-iphone-experience-with-ios-26/](https://www.apple.com/newsroom/2025/06/apple-elevates-the-iphone-experience-with-ios-26/)
22. Apple supercharges its tools and technologies for developers, accessed June 14, 2025, [https://www.apple.com/newsroom/2025/06/apple-supercharges-its-tools-and-technologies-for-developers/](https://www.apple.com/newsroom/2025/06/apple-supercharges-its-tools-and-technologies-for-developers/)
23. Getting Started With Apple's Vision Framework: A Developer's Perspective \- HackerNoon, accessed June 14, 2025, [https://hackernoon.com/getting-started-with-apples-vision-framework-a-developers-perspective](https://hackernoon.com/getting-started-with-apples-vision-framework-a-developers-perspective)
24. Recognizing Text in Images | Apple Developer Documentation, accessed June 14, 2025, [https://developer.apple.com/documentation/vision/recognizing-text-in-images](https://developer.apple.com/documentation/vision/recognizing-text-in-images)
25. RecognizeTextRequest | Apple Developer Documentation, accessed June 14, 2025, [https://developer.apple.com/documentation/vision/recognizetextrequest](https://developer.apple.com/documentation/vision/recognizetextrequest)
26. Vision | Apple Developer Documentation, accessed June 14, 2025, [https://developer.apple.com/documentation/vision/](https://developer.apple.com/documentation/vision/)
27. Code-along: Bring on-device AI to your app using the Foundation Models framework \- WWDC25 \- Videos \- Apple Developer, accessed June 14, 2025, [https://developer.apple.com/videos/play/wwdc2025/259/](https://developer.apple.com/videos/play/wwdc2025/259/)
28. Foundation Models | Apple Developer Documentation, accessed June 14, 2025, [https://developer.apple.com/documentation/foundationmodels](https://developer.apple.com/documentation/foundationmodels)
29. Meet the Foundation Models framework | Documentation \- WWDC Notes, accessed June 14, 2025, [https://wwdcnotes.com/documentation/wwdcnotes/wwdc25-286-meet-the-foundation-models-framework/](https://wwdcnotes.com/documentation/wwdcnotes/wwdc25-286-meet-the-foundation-models-framework/)
30. Deep dive into the Foundation Models framework \- WWDC25 \- Videos \- Apple Developer, accessed June 14, 2025, [https://developer.apple.com/videos/play/wwdc2025/301/](https://developer.apple.com/videos/play/wwdc2025/301/)
31. Discover machine learning & AI frameworks on Apple platforms ..., accessed June 14, 2025, [https://developer.apple.com/videos/play/wwdc2025/360](https://developer.apple.com/videos/play/wwdc2025/360)
32. Generating content and performing tasks with Foundation Models \- Apple Developer, accessed June 14, 2025, [https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models](https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models)
33. Apple just gave developers access to its new local AI models, here's how they perform, accessed June 14, 2025, [https://www.reddit.com/r/apple/comments/1l9542u/apple_just_gave_developers_access_to_its_new/](https://www.reddit.com/r/apple/comments/1l9542u/apple_just_gave_developers_access_to_its_new/)
34. Updates to Apple's On-Device and Server Foundation Language Models, accessed June 14, 2025, [https://machinelearning.apple.com/research/apple-foundation-models-2025-updates](https://machinelearning.apple.com/research/apple-foundation-models-2025-updates)
35. Here Are All the iOS 26 Features That Require iPhone 15 Pro or Newer \- MacRumors, accessed June 14, 2025, [https://www.macrumors.com/2025/06/12/all-ios-26-features-require-iphone-15-pro-newer/](https://www.macrumors.com/2025/06/12/all-ios-26-features-require-iphone-15-pro-newer/)
36. Core ML | Apple Developer Documentation, accessed June 14, 2025, [https://developer.apple.com/documentation/coreml/](https://developer.apple.com/documentation/coreml/)
37. What Is Core ML Tools?, accessed June 14, 2025, [https://apple.github.io/coremltools/docs-guides/source/overview-coremltools.html](https://apple.github.io/coremltools/docs-guides/source/overview-coremltools.html)
38. Core ML Models \- Machine Learning \- Apple Developer, accessed June 14, 2025, [https://developer.apple.com/machine-learning/models/](https://developer.apple.com/machine-learning/models/)
39. Core ML \- Machine Learning \- Apple Developer, accessed June 14, 2025, [https://developer.apple.com/machine-learning/core-ml/](https://developer.apple.com/machine-learning/core-ml/)
40. Back in trend? Liquid Glass : r/UXDesign \- Reddit, accessed June 14, 2025, [https://www.reddit.com/r/UXDesign/comments/1l7rpmu/back_in_trend_liquid_glass/](https://www.reddit.com/r/UXDesign/comments/1l7rpmu/back_in_trend_liquid_glass/)
41. Locating and displaying recognized text | Apple Developer Documentation, accessed June 14, 2025, [https://developer.apple.com/documentation/vision/locating-and-displaying-recognized-text](https://developer.apple.com/documentation/vision/locating-and-displaying-recognized-text)
