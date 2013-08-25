Phitext
========

Phitext is the first rich text editor library for iPhone OS developers who want more control over UITextView but don't want to resort to private API calls.

The library takes advantage of the UITextView protocol introduced in iPhone OS 3.2 (and available in 4.0) to accept input from the system (or custom) keyboard. Phitext overcomes the challenges of implementing the UITextView protocol in the face of sparse Apple documentation. Because Phitext is backed by an NSAttributedString and uses Core Text to render it's content the developer is free to add any style attributes supported by NSAttributedString and Core Text.

Getting Started
---------------

You may like to start at the [Phitext-workspace] repository, which will get you started with a workspace and submodules for this and related projects.

To use the library in your projects:

1. Clone or download this repository.
2. Drag and drop the Xcode project into your Xcode workspace.
3. Add the Phitext.a static library to your project's Linked Frameworks and Libraries.
4. From your target's (or project's) Build Settings, ensure that *Other Linker Flags* (`OTHER_LDFLAGS`) contains `-ObjC`.
5. In your storyboard, add a `UIScrollView` and set its Custom Class to `PhiTextEditorView`, from the Identity Inspector.
6. Programmatically set the `NSAttributedString` in the `PhiTextStorage` object of the `PhiTextDocument` associated with every `PhiTextEditorView`.

See the sample code in [Phitext-workspace] repository for more details.

Contributing
------------

Pull requests are welcome.

License
-------

[Apache](NOTICE)

[Phitext-workspace]: https://github.com/au-phiware/Phitext-workspace
