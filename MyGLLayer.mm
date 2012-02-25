#import "MyGLLayer.h"
#import <OpenGL/glu.h> 

@implementation MyGLLayer

- (id)init
{
	self = [super init];
	if (! self)
		return nil;

	self.asynchronous = TRUE; // Request we get redrawn every frame.
	self.needsDisplayOnBoundsChange = TRUE; // Make sure we get resized when the view is resized.

	return self;
}

- (BOOL)canDrawInCGLContext:(CGLContextObj)context
                pixelFormat:(CGLPixelFormatObj)pixelFormat 
               forLayerTime:(CFTimeInterval)timeInterval 
                displayTime:(const CVTimeStamp *)timeStamp
{
	return YES;
}

static void ReportGLErrors()
{
	GLenum err;
	while ((err = glGetError()) != 0)
		NSLog(@"GL error: %"PRIu32".\n", (uint32_t) err);
}

- (void)drawInCGLContext:(CGLContextObj)context
             pixelFormat:(CGLPixelFormatObj)pixelFormat 
            forLayerTime:(CFTimeInterval)interval 
             displayTime:(const CVTimeStamp *)timeStamp
{
	const int width = (int) self.bounds.size.width;
	const int height = (int) self.bounds.size.height;
	const float aspectRatio = (float) width / height;
	const double time = [[NSDate date] timeIntervalSince1970];

	// Remember the CAOpenGLLayer's target framebuffer.
	GLint layerFBO = 0;
	glGetIntegerv(GL_FRAMEBUFFER_BINDING, &layerFBO);
	
	if (fboWidth != width || fboHeight != height) {
		// Create/recreate the framebuffer object with the new size.
		fboWidth = width;
		fboHeight = height;
		
		if (! fbo)
			glGenFramebuffers(1, &fbo);
			
		glBindFramebuffer(GL_FRAMEBUFFER, fbo);

		// Use the maximum number of multisample samples we can manage.
		GLint multisampleCount = 0;
		glGetIntegerv(GL_MAX_SAMPLES, &multisampleCount);
		
		// Create and attach a depth buffer.
		if (! fboDepthBuffer)
			glGenRenderbuffers(1, &fboDepthBuffer);
		glBindRenderbuffer(GL_RENDERBUFFER, fboDepthBuffer);
		glRenderbufferStorageMultisample(GL_RENDERBUFFER, multisampleCount, GL_DEPTH_COMPONENT, fboWidth, fboHeight);

		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, fboDepthBuffer);

		// Create and attach a colour buffer.
		if (! fboColorBuffer)
			glGenRenderbuffers(1, &fboColorBuffer);
		glBindRenderbuffer(GL_RENDERBUFFER, fboColorBuffer);
		glRenderbufferStorageMultisample(GL_RENDERBUFFER, multisampleCount, GL_RGBA, fboWidth, fboHeight);
		
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, fboColorBuffer);
	}

	glBindFramebuffer(GL_FRAMEBUFFER, fbo);
	
	GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
	if (status != GL_FRAMEBUFFER_COMPLETE) {
		NSLog(@"Framebuffer not complete. Will retry on the next frame.\n");
		fboWidth = -1;
		fboHeight = -1;
		return;
	}

	ReportGLErrors();
	
	// Draw in to our multisampled framebuffer.
	
	glViewport(0, 0, fboWidth, fboHeight);
	
	glClearColor(1.0f, 0.5f, 0.0f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluPerspective(90.0f, aspectRatio, 0.1f, 5000.0f);

	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

	glTranslatef(0.0f, 0.0f, -12.0f);
	glRotatef((float) fmod(time, 10.0) * 360.0f * 0.1f, 0.0f, 0.0f, 1.0f);
	
	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LEQUAL);

	glBegin(GL_TRIANGLES);
		glColor3f(1.0f, 0.0f, 0.0f);
		glVertex3f(0.0f, 10.0f, 0.0f);
		glColor3f(0.0f, 1.0f, 0.0f);
		glVertex3f(10.0f, 0.0f, 0.0f);
		glColor3f(0.0f, 0.0f, 1.0f);
		glVertex3f(-10.0f, -10.0f, 0.0f);
	glEnd();

	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

	glTranslatef(0.0f, 0.0f, -12.0f);
	glRotatef((float) fmod(time, 10.0) * 360.0f * 0.1f, 0.0f, 1.0f, 0.0f);

	glBegin(GL_TRIANGLES);
		glColor3f(1.0f, 0.0f, 0.0f);
		glVertex3f(0.0f, 10.0f, 0.0f);
		glColor3f(0.0f, 1.0f, 0.0f);
		glVertex3f(10.0f, 0.0f, 0.0f);
		glColor3f(0.0f, 0.0f, 1.0f);
		glVertex3f(-10.0f, -10.0f, 0.0f);
	glEnd();
	
	// Now blit from our multisampled framebuffer to the CAOpenGLLayer's framebuffer.

	glBindFramebuffer(GL_READ_FRAMEBUFFER, fbo);
	glBindFramebuffer(GL_DRAW_FRAMEBUFFER, layerFBO);

	glBlitFramebuffer(0, 0, fboWidth, fboHeight, 0, 0, width, height, GL_COLOR_BUFFER_BIT, GL_LINEAR);
	
	// And set the CAOpenGLLayer's framebuffer as the current framebuffer before we end,.

	glBindFramebuffer(GL_FRAMEBUFFER, layerFBO);
}

- (CGLPixelFormatObj)copyCGLPixelFormatForDisplayMask:(uint32_t)mask 
{
	// Specifying multisampling in the pixel format doesn't work. I'm assuming CAOpenGLLayer uses render to texture.
	// Note that I also don't request a depth buffer or stencil buffer, since we'll have to create them ourself for
	// multisampling.
	CGLPixelFormatAttribute attributes[] = {
		kCGLPFADisplayMask, (CGLPixelFormatAttribute) mask,
		kCGLPFAAccelerated,
		kCGLPFAColorSize, (CGLPixelFormatAttribute) 24,
		kCGLPFAAlphaSize, (CGLPixelFormatAttribute) 8,
		kCGLPFANoRecovery,
		(CGLPixelFormatAttribute) 0
	};

	CGLPixelFormatObj pixelFormat = NULL;
	GLint numPixelFormats = 0;
	CGLChoosePixelFormat(attributes, &pixelFormat, &numPixelFormats);
	if (! pixelFormat)
		NSLog(@"Error: Could not choose pixel format!");

	return pixelFormat;
}

- (void)releaseCGLPixelFormat:(CGLPixelFormatObj)pixelFormat
{
	CGLDestroyPixelFormat(pixelFormat);
}

- (CGLContextObj)copyCGLContextForPixelFormat:(CGLPixelFormatObj)pixelFormat 
{
	CGLContextObj context = NULL;
	CGLCreateContext(pixelFormat, NULL, &context);
	if(context == NULL)
		NSLog(@"Error: Could not create context!");
		

	CGLSetCurrentContext(context);
	
	// Set up OpenGL context here
	
	return context;
}

- (void)releaseCGLContext:(CGLContextObj)context
{
	// Clean up OpenGL context here
	
	CGLDestroyContext(context);
}

@end
