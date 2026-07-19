# Delphi TEdgeBrowser PDF Viewer

TEdgeBrowser maps a local folder to a virtual host (`pdfviewer.local`)

## External Libs Used
* [PDF.js](https://github.com/mozilla/pdf.js/) - Handles the actual PDF rendering inside the browser component and used the viewer.html from here.
* [pdf-lib](https://github.com/Hopding/pdf-lib) - added it to the viewer.html to read and write annotations directly to the PDF byte array.

## Web Assets Folder
 - move it next to the .exe/Into the output folder

## Microsoft WebView2Loader.dll
 - move the WebView2Loader.dll into the output folder as well
 - more infos about the EdgeView2 SDK you can find in the [Embarcadero RAD Studio Documentation](https://docwiki.embarcadero.com/RADStudio/en/Using_TEdgeBrowser_Component_and_Changes_to_the_TWebBrowser_Component).

