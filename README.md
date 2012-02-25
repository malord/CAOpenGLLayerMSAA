# CAOpenGLLayerMSAA

Demonstrates how to use MSAA (antialiasing) inside a CAOpenGLLayer, and how a CAOpenGLLayer backed view can have subviews, unlike an NSOpenGLView.

May require OS X 10.7 - I've not got a 10.6 machine to test on. It could just be that certain OpenGL calls need to have their extension suffix appended (e.g., `glBlitFramebuffer` may need to be `glBlitFramebufferEXT`). If you want to try it on 10.6, you'll need to change the Deployment Target (currently 10.7).

I've used Automatic Reference Counting, so that might need tweaking too to support 10.6.


